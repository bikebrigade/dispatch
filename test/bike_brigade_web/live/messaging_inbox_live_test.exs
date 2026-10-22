defmodule BikeBrigadeWeb.MessagingInboxLiveTest do
  use BikeBrigadeWeb.ConnCase
  import Phoenix.LiveViewTest
  alias BikeBrigade.{Accounts, Messaging, Repo}
  setup [:login, :opt_in]

  # Messages sent within the same second have no guaranteed order, so look them up by text.
  defp message_to(rider, text) do
    Enum.find(Messaging.latest_messages(rider), &(&1.body =~ text))
  end

  defp count_items(html) do
    html |> Floki.parse_fragment!() |> Floki.find("#conversation-list > li") |> length()
  end

  defp opt_in(%{user: user}) do
    {:ok, user} = Accounts.update_user_as_admin(user, %{flags: %{unified_messaging: true}})
    %{user: user}
  end

  describe "routing" do
    test "opted-in dispatchers are routed to the inbox", %{conn: conn} do
      assert {:error, {:live_redirect, %{to: to}}} = live(conn, ~p"/messages")
      assert to =~ "/messages/inbox"

      rider = fixture(:rider)
      assert {:error, {:live_redirect, %{to: to}}} = live(conn, ~p"/messages/#{rider}")
      assert to =~ "rider=#{rider.id}"

      assert {:error, {:live_redirect, %{to: to}}} = live(conn, ~p"/messages/new")
      assert to =~ "compose=new"

      assert {:error, {:live_redirect, %{to: to}}} = live(conn, ~p"/messages/#{rider}/tasks")
      assert to =~ "panel=deliveries"
      assert to =~ "rider=#{rider.id}"

      {:ok, view, _} = live(conn, ~p"/messages/inbox")
      assert has_element?(view, "#messaging-inbox")
      refute has_element?(view, "#new-bulk")
    end

    test "dispatchers who are not opted in keep the old page", %{conn: conn, user: user} do
      {:ok, _} = Accounts.update_user_as_admin(user, %{flags: %{unified_messaging: false}})
      {:ok, _, html} = live(conn, ~p"/messages")
      refute html =~ "messaging-inbox"

      assert {:error, {:live_redirect, %{to: "/messages", flash: flash}}} =
               live(conn, ~p"/messages/inbox")

      assert flash["error"] =~ "isn't enabled"
    end

    test "malformed params are ignored", %{conn: conn} do
      {:ok, view, _} = live(conn, "/messages/inbox?search[]=x&rider[]=1&tab[]=groups")
      assert has_element?(view, "#inbox-riders")
    end
  end

  describe "all conversations" do
    test "legacy unnamed riders remain searchable and usable", %{conn: conn} do
      import Ecto.Query
      rider = fixture(:rider)
      fixture(:sms_message_from_rider, rider)

      Repo.update_all(from(r in BikeBrigade.Riders.Rider, where: r.id == ^rider.id),
        set: [name: nil]
      )

      {:ok, view, _} = live(conn, ~p"/messages/inbox?rider=#{rider.id}")
      assert has_element?(view, "#conversation-form")
      assert has_element?(view, "#inbox-riders", rider.phone)
    end

    test "conversations load a page at a time and search the whole list", %{conn: conn} do
      # Created first, so with every message sent in the same second it sorts last.
      oldest = fixture(:rider, %{name: "Zelda Oldest"})
      fixture(:sms_message_from_rider, oldest)

      for _ <- 1..50, do: fixture(:sms_message_from_rider, fixture(:rider))

      {:ok, view, _} = live(conn, ~p"/messages/inbox")
      assert has_element?(view, "#conversation-list[phx-viewport-bottom]")
      refute has_element?(view, "#conversation-list-item\\:#{oldest.id}")

      render_hook(view, "load_more_conversations", %{})
      assert has_element?(view, "#conversation-list-item\\:#{oldest.id}")
      assert view |> element("#conversation-list") |> render() |> count_items() == 51
      refute has_element?(view, "#conversation-list[phx-viewport-bottom]")

      {:ok, view, _} = live(conn, ~p"/messages/inbox?search=zelda")
      assert has_element?(view, "#conversation-list-item\\:#{oldest.id}")
      assert view |> element("#conversation-list") |> render() |> count_items() == 1
    end

    test "incoming messages preserve a composed reply", %{conn: conn} do
      rider = fixture(:rider)
      fixture(:sms_message_from_rider, rider)
      {:ok, view, _} = live(conn, ~p"/messages/inbox?rider=#{rider.id}")

      view
      |> form("#conversation-form", %{sms_message: %{body: "Keep my draft"}})
      |> render_change()

      fixture(:sms_message_from_rider, rider, %{body: "New incoming message"})
      assert has_element?(view, "#conversation-form textarea", "Keep my draft")
      assert render(view) =~ "New incoming message"
    end
  end

  describe "campaigns" do
    test "campaigns use this week and program lead, without saving a duplicate group", %{
      conn: conn,
      user: user
    } do
      p = fixture(:program, %{lead_id: user.id})
      now = BikeBrigade.LocalizedDateTime.now()

      campaign =
        fixture(:campaign, %{
          program_id: p.id,
          delivery_start: now,
          delivery_end: DateTime.add(now, 3600)
        })

      other = fixture(:campaign, %{delivery_start: now, delivery_end: DateTime.add(now, 3600)})
      rider = fixture(:rider)
      BikeBrigade.Delivery.create_campaign_rider(%{campaign_id: campaign.id, rider_id: rider.id})
      {:ok, view, _} = live(conn, ~p"/messages/inbox?tab=campaigns")
      assert has_element?(view, "#inbox-contexts", BikeBrigadeWeb.CampaignHelpers.name(campaign))
      refute has_element?(view, "#inbox-contexts", BikeBrigadeWeb.CampaignHelpers.name(other))
      task = fixture(:task, %{campaign: campaign, rider: rider})
      fixture(:task, %{campaign: campaign, rider: rider})

      {:ok, view, _} = live(conn, ~p"/messages/inbox?tab=campaigns&context=#{campaign.id}")
      refute has_element?(view, "#new-bulk")

      assert has_element?(
               view,
               "#merged-inbox [data-rider-id='#{rider.id}'] [data-deliveries]",
               "0/2"
             )

      BikeBrigade.Delivery.update_task(task, %{delivery_status: :completed})

      assert has_element?(
               view,
               "#merged-inbox [data-rider-id='#{rider.id}'] [data-deliveries]",
               "1/2"
             )

      refute has_element?(view, "#everyone-drawer")
      view |> element("#message-everyone") |> render_click()

      view
      |> form("#group-message-form", %{everyone: %{body: "Pickup moved"}})
      |> render_submit()

      refute has_element?(view, "#everyone-drawer")
      assert Messaging.list_bulk_message_groups() == []
      assert message_to(rider, "Pickup moved").campaign_id == campaign.id
    end

    test "Only my campaigns toggles between my and all campaigns", %{conn: conn, user: user} do
      mine = fixture(:campaign, %{program_id: fixture(:program, %{lead_id: user.id}).id})
      other = fixture(:campaign)
      name = &BikeBrigadeWeb.CampaignHelpers.name/1

      {:ok, view, _} = live(conn, ~p"/messages/inbox?tab=campaigns")
      assert has_element?(view, "#inbox-mine[role=switch][aria-checked=true]")
      refute has_element?(view, "#inbox-contexts", name.(other))

      view |> element("#inbox-mine") |> render_click()
      assert_patch(view, ~p"/messages/inbox?mine=false&tab=campaigns")
      assert has_element?(view, "#inbox-contexts", name.(other))
      assert has_element?(view, "#inbox-contexts", name.(mine))
    end

    test "the campaign page's link opens its campaign even outside this week", %{conn: conn} do
      next_month = DateTime.add(BikeBrigade.LocalizedDateTime.now(), 30, :day)

      campaign =
        fixture(:campaign, %{
          delivery_start: next_month,
          delivery_end: DateTime.add(next_month, 3600)
        })

      rider = fixture(:rider)
      BikeBrigade.Delivery.create_campaign_rider(%{campaign_id: campaign.id, rider_id: rider.id})

      {:ok, view, _} =
        live(conn, ~p"/messages/inbox?tab=campaigns&context=#{campaign.id}&mine=false")

      assert has_element?(view, "#merged-inbox [data-rider-id='#{rider.id}']")
      assert has_element?(view, "#message-everyone")

      {:ok, view, _} = live(conn, ~p"/messages/inbox?tab=campaigns&context=not-a-campaign")
      refute has_element?(view, "#message-everyone")
    end
  end

  describe "bulk messages" do
    test "saved groups persist recipients and creator, and replies remain individual", %{
      conn: conn,
      user: user
    } do
      {:ok, user} = Accounts.update_user_as_admin(user, %{signature_on_messages: "Dispatch"})

      r1 = fixture(:rider)
      r2 = fixture(:rider)

      assert {:ok, result} =
               Messaging.send_bulk_message(user, %{
                 rider_ids: [r1.id, r2.id],
                 body: "Backup riders?",
                 save_group: true,
                 group_name: "Backup riders"
               })

      assert result.sent == 2
      assert result.failed == []
      [group] = Messaging.list_bulk_message_groups()
      assert group.creator.id == user.id
      assert Enum.sort(Enum.map(group.riders, & &1.id)) == Enum.sort([r1.id, r2.id])

      {:ok, view, _} =
        live(conn, ~p"/messages/inbox?tab=groups&context=#{group.id}&rider=#{r1.id}")

      assert has_element?(view, "#message-everyone")
      assert has_element?(view, "#new-bulk")
      view |> form("#conversation-form", %{sms_message: %{body: "Only you"}}) |> render_submit()
      assert message_to(r1, "Only you")
      refute message_to(r2, "Only you")
      render_patch(view, ~p"/messages/inbox?tab=groups&context=#{group.id}&search=#{r1.name}")
      view |> element("#message-everyone") |> render_click()

      view
      |> form("#group-message-form", %{everyone: %{body: "Everyone again"}})
      |> render_submit()

      assert message_to(r1, "Everyone again")
      assert message_to(r2, "Everyone again")
      assert length(Messaging.list_bulk_message_groups()) == 1
      assert Repo.get!(BikeBrigade.Messaging.BulkMessageGroup, group.id).body == "Backup riders?"
    end

    test "saving a group needs a name, and the drawer starts empty when reopened", %{conn: conn} do
      {:ok, view, _} = live(conn, ~p"/messages/inbox?tab=groups")
      view |> element("#new-bulk") |> render_click()
      assert has_element?(view, "#new-bulk-message")

      view |> form("#inbox-bulk-form", %{bulk_message: %{body: "Hello"}}) |> render_change()
      refute has_element?(view, "#inbox-bulk-form input[name='bulk_message[group_name]']")

      view |> element("#save-group-toggle") |> render_click()
      assert has_element?(view, "#save-group-toggle[aria-checked=true]")
      assert has_element?(view, "#inbox-bulk-form input[name='bulk_message[group_name]']")
      # Toggling keeps what was already typed.
      assert has_element?(view, "#inbox-bulk-form textarea[name='bulk_message[body]']", "Hello")

      view |> form("#inbox-bulk-form", %{bulk_message: %{body: "Hello"}}) |> render_submit()

      assert has_element?(view, "#inbox-bulk-form", "Enter a name for the group")

      view |> element("#new-bulk-message a", "Cancel") |> render_click()
      refute has_element?(view, "#new-bulk-message")

      view |> element("#new-bulk") |> render_click()
      refute has_element?(view, "#inbox-bulk-form", "Enter a name for the group")
      refute has_element?(view, "#inbox-bulk-form input[name='bulk_message[group_name]']")
      assert has_element?(view, "#inbox-bulk-form textarea[name='bulk_message[body]']", "")
    end

    test "closing a drawer opened from /messages/new drops it from the URL", %{conn: conn} do
      {:ok, view, _} = live(conn, ~p"/messages/inbox?tab=groups&compose=new")
      view |> element("#new-bulk-message a", "Cancel") |> render_click()
      assert_patch(view, ~p"/messages/inbox?tab=groups")
      refute has_element?(view, "#new-bulk-message")
    end

    test "new bulk message requires picking recipients", %{conn: conn} do
      rider = fixture(:rider)
      {:ok, view, _} = live(conn, ~p"/messages/inbox?tab=groups")
      view |> element("#new-bulk") |> render_click()

      view |> form("#inbox-bulk-form", %{bulk_message: %{body: "Hello"}}) |> render_submit()
      assert has_element?(view, "#inbox-bulk-form", "Select at least one rider")

      view |> element("#inbox-rider-select-input") |> render_keyup(%{"value" => rider.name})
      view |> element("[id='rider-selection:#{rider.id}'] a") |> render_click()
      view |> form("#inbox-bulk-form", %{bulk_message: %{body: "Hello"}}) |> render_submit()
      assert message_to(rider, "Hello")
      assert Messaging.list_bulk_message_groups() == []
    end

    test "sending from /messages/new closes the drawer for good", %{conn: conn} do
      rider = fixture(:rider)
      {:ok, view, _} = live(conn, ~p"/messages/inbox?tab=groups&compose=new")

      view |> element("#inbox-rider-select-input") |> render_keyup(%{"value" => rider.name})
      view |> element("[id='rider-selection:#{rider.id}'] a") |> render_click()
      view |> form("#inbox-bulk-form", %{bulk_message: %{body: "Hello"}}) |> render_submit()

      assert message_to(rider, "Hello")
      assert_patch(view, ~p"/messages/inbox?tab=groups")
      refute has_element?(view, "#new-bulk-message")

      # Navigating elsewhere doesn't bring it back.
      render_patch(view, ~p"/messages/inbox?tab=campaigns")
      refute has_element?(view, "#new-bulk-message")
    end

    test "photos that can't be attached block sending instead of crashing", %{conn: conn} do
      rider = fixture(:rider)
      {:ok, view, _} = live(conn, ~p"/messages/inbox?tab=groups&compose=new")

      upload =
        file_input(view, "#inbox-bulk-form", :media, [
          %{name: "notes.txt", content: "not a photo", type: "text/plain"}
        ])

      assert {:error, _} = render_upload(upload, "notes.txt")

      view |> element("#inbox-rider-select-input") |> render_keyup(%{"value" => rider.name})
      view |> element("[id='rider-selection:#{rider.id}'] a") |> render_click()
      html = view |> form("#inbox-bulk-form", %{bulk_message: %{body: ""}}) |> render_submit()

      assert html =~ "Remove the photos that can&#39;t be attached"
      assert has_element?(view, "#new-bulk-message")
      refute message_to(rider, "")
    end

    test "an unknown bulk message selects nothing", %{conn: conn} do
      group = fixture(:bulk_message_group, %{name: "Evening crew"})

      {:ok, view, _} = live(conn, ~p"/messages/inbox?tab=groups")
      assert has_element?(view, "#merged-inbox h2", "Evening crew")

      {:ok, view, _} = live(conn, ~p"/messages/inbox?tab=groups&context=#{group.id + 1}")
      refute has_element?(view, "#merged-inbox h2", "Evening crew")
      refute has_element?(view, "#message-everyone")
    end
  end

  describe "deliveries panel" do
    test "deliveries panel shows today's tasks and toggles them delivered", %{conn: conn} do
      rider = fixture(:rider)
      task = fixture(:task, %{rider: rider, dropoff_name: "Jordan"})
      fixture(:sms_message_from_rider, rider)

      {:ok, _} =
        BikeBrigade.Delivery.create_campaign_rider(%{
          campaign_id: task.campaign_id,
          rider_id: rider.id,
          pickup_window: "4:15–4:30 PM"
        })

      {:ok, view, _} = live(conn, ~p"/messages/inbox?rider=#{rider.id}")

      # Always beside the chat on xl screens; narrower screens get a summary bar instead.
      assert has_element?(view, "#rider-deliveries.hidden.xl\\:flex")
      assert has_element?(view, "#rider-delivery-#{task.id}", "Jordan")
      assert has_element?(view, "#rider-deliveries", "4:15–4:30 PM")
      assert has_element?(view, "#deliveries-bar.xl\\:hidden", "0 of 1 done")

      view |> element("#deliveries-bar") |> render_click()
      assert_patch(view, ~p"/messages/inbox?panel=deliveries&rider=#{rider.id}")
      refute has_element?(view, "#rider-deliveries.hidden")

      toggle = element(view, "#rider-delivery-#{task.id} [role=checkbox]")
      render_click(toggle)
      assert BikeBrigade.Delivery.get_task(task.id).delivery_status == :completed
      assert has_element?(view, "#deliveries-bar", "1 of 1 done")
      assert has_element?(view, "#rider-delivery-#{task.id} [aria-checked=true]")

      render_click(toggle)
      assert BikeBrigade.Delivery.get_task(task.id).delivery_status == :pending

      view |> element("#rider-deliveries a[aria-label='Back to conversation']") |> render_click()
      assert_patch(view, ~p"/messages/inbox?rider=#{rider.id}")
      assert has_element?(view, "#rider-deliveries.hidden")
    end

    test "riders without recent deliveries have no deliveries bar or panel", %{conn: conn} do
      rider = fixture(:rider)
      fixture(:sms_message_from_rider, rider)

      for panel <- ["", "deliveries"] do
        {:ok, view, _} = live(conn, ~p"/messages/inbox?rider=#{rider.id}&panel=#{panel}")
        refute has_element?(view, "#deliveries-bar")
        refute has_element?(view, "#rider-deliveries")
      end
    end
  end

  describe "live updates" do
    test "groups saved by another dispatcher appear in Bulk messages", %{conn: conn} do
      {:ok, view, _} = live(conn, ~p"/messages/inbox?tab=groups")
      refute has_element?(view, "#inbox-contexts", "Evening crew")

      other_dispatcher = fixture(:user, %{is_dispatcher: true})

      fixture(:bulk_message_group, %{creator: other_dispatcher, name: "Evening crew"})

      assert has_element?(view, "#inbox-contexts", "Evening crew")
      assert has_element?(view, "#inbox-tab-groups", "1")
    end

    test "new messages update the All conversations list", %{conn: conn} do
      quiet = fixture(:rider)
      fixture(:sms_message_from_rider, quiet, %{body: "Earlier"})
      newcomer = fixture(:rider)

      {:ok, view, _} = live(conn, ~p"/messages/inbox?rider=#{quiet.id}")
      refute has_element?(view, "#conversation-list-item\\:#{newcomer.id}")

      fixture(:sms_message_from_rider, newcomer, %{body: "First text"})
      assert has_element?(view, "#conversation-list-item\\:#{newcomer.id}", "First text")

      fixture(:sms_message_from_rider, quiet, %{body: "Following up"})
      assert has_element?(view, "#conversation-list-item\\:#{quiet.id}", "Following up")
    end

    test "new messages update the campaign roster, task changes update its delivery chips",
         %{conn: conn, user: user} do
      campaign = fixture(:campaign, %{program_id: fixture(:program, %{lead_id: user.id}).id})
      other_campaign = fixture(:campaign)
      rider = fixture(:rider)
      task = fixture(:task, %{campaign: campaign, rider: rider})
      other_task = fixture(:task, %{campaign: other_campaign, rider: rider})
      row = "#merged-inbox [data-rider-id='#{rider.id}']"

      {:ok, view, _} = live(conn, ~p"/messages/inbox?tab=campaigns&context=#{campaign.id}")
      assert has_element?(view, "#{row} [data-deliveries]", "0/1")

      fixture(:sms_message_from_rider, rider, %{body: "At the door"})
      assert has_element?(view, row, "At the door")

      # Another campaign's tasks don't affect this roster.
      BikeBrigade.Delivery.update_task(other_task, %{delivery_status: :completed})
      assert has_element?(view, "#{row} [data-deliveries]", "0/1")

      BikeBrigade.Delivery.update_task(task, %{delivery_status: :completed})
      assert has_element?(view, "#{row} [data-deliveries]", "1/1")
    end

    test "riders added to the selected campaign join its roster", %{conn: conn, user: user} do
      campaign = fixture(:campaign, %{program_id: fixture(:program, %{lead_id: user.id}).id})
      rider = fixture(:rider)

      {:ok, view, _} = live(conn, ~p"/messages/inbox?tab=campaigns&context=#{campaign.id}")
      refute has_element?(view, "#merged-inbox [data-rider-id='#{rider.id}']")

      BikeBrigade.Delivery.create_campaign_rider(%{campaign_id: campaign.id, rider_id: rider.id})
      assert has_element?(view, "#merged-inbox [data-rider-id='#{rider.id}']")
    end

    test "unrelated messages are ignored", %{conn: conn} do
      {:ok, view, _} = live(conn, ~p"/messages/inbox")
      send(view.pid, :something_else)
      send(view.pid, {:opportunity_updated, %{}})
      assert has_element?(view, "#messaging-inbox")
    end
  end
end
