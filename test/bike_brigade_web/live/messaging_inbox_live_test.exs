defmodule BikeBrigadeWeb.MessagingInboxLiveTest do
  use BikeBrigadeWeb.ConnCase
  import Phoenix.LiveViewTest
  alias BikeBrigade.{Accounts, Messaging, Repo}
  alias BikeBrigade.Messaging.Inbox
  setup [:login]

  test "user edit retains the opt-in during validation and rollout task can disable it", %{
    conn: conn,
    user: user
  } do
    {:ok, view, _} = live(conn, ~p"/users/#{user.id}/edit")
    view |> form("#user-form", %{user: %{unified_messaging: "true"}}) |> render_change()
    assert has_element?(view, "#user-unified-messaging[checked]")
    view |> form("#user-form", %{user: %{unified_messaging: "true"}}) |> render_submit()
    assert Inbox.enabled?(Accounts.get_user(user.id))
    Mix.Tasks.FeatureFlags.run(["unified_messaging", "user", user.email, "false"])
    refute Inbox.enabled?(Accounts.get_user(user.id))
  end

  test "legacy unnamed riders remain searchable and usable", %{conn: conn, user: user} do
    import Ecto.Query
    {:ok, _} = Accounts.update_user_as_admin(user, %{flags: %{"unified_messaging" => true}})
    rider = fixture(:rider)
    fixture(:sms_message_from_rider, rider)

    Repo.update_all(from(r in BikeBrigade.Riders.Rider, where: r.id == ^rider.id),
      set: [name: nil]
    )

    {:ok, view, _} = live(conn, ~p"/messages/inbox?rider=#{rider.id}")
    assert has_element?(view, "#conversation-form")
    assert has_element?(view, "#inbox-riders", rider.phone)
  end

  defmodule SelectiveFailureAdapter do
    def send_sms(payload) do
      if payload[:to] == Application.get_env(:bike_brigade, :inbox_test_failed_phone) do
        {:error, "Test transport failure"}
      else
        {:ok, %{status: "queued", sid: "TEST#{Ecto.UUID.generate()}"}}
      end
    end
  end

  test "partial transport failures preserve saved recipients and report failed riders", %{
    user: user
  } do
    successful = fixture(:rider, %{flags: %{initial_message_sent: true}})
    failed = fixture(:rider)
    config = Application.fetch_env!(:bike_brigade, :sms_service)

    Application.put_env(
      :bike_brigade,
      :sms_service,
      Keyword.put(config, :adapter, SelectiveFailureAdapter)
    )

    Application.put_env(:bike_brigade, :inbox_test_failed_phone, failed.phone)

    on_exit(fn ->
      Application.put_env(:bike_brigade, :sms_service, config)
      Application.delete_env(:bike_brigade, :inbox_test_failed_phone)
    end)

    assert {:ok, result} =
             Inbox.send(user, [successful.id, failed.id], "Test message",
               save: true,
               name: "Retry cohort"
             )

    assert result.sent == 1
    assert Enum.map(result.failed, & &1.id) == [failed.id]
    assert length(hd(Inbox.groups()).riders) == 2
    assert List.last(Messaging.latest_messages(successful)).body == "Test message"
    assert Messaging.latest_messages(failed) == []
  end

  test "incoming messages preserve a composed reply", %{conn: conn, user: user} do
    {:ok, _} = Accounts.update_user_as_admin(user, %{flags: %{"unified_messaging" => true}})
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

  test "opt-in routes dispatchers to the inbox and disabled users keep the old page", %{
    conn: conn,
    user: user
  } do
    {:ok, _, html} = live(conn, ~p"/messages")
    refute html =~ "messaging-inbox"
    assert {:error, {:redirect, %{to: "/messages"}}} = live(conn, ~p"/messages/inbox")
    {:ok, _} = Accounts.update_user_as_admin(user, %{flags: %{"unified_messaging" => true}})
    assert {:error, {:live_redirect, %{to: destination}}} = live(conn, ~p"/messages")
    assert destination =~ "/messages/inbox"
    {:ok, view, _} = live(conn, ~p"/messages/inbox")
    assert has_element?(view, "#messaging-inbox")
    refute has_element?(view, "#new-bulk")
  end

  test "saved groups persist recipients and creator, and replies remain individual", %{
    conn: conn,
    user: user
  } do
    {:ok, user} =
      Accounts.update_user_as_admin(user, %{
        flags: %{"unified_messaging" => true},
        signature_on_messages: "Dispatch"
      })

    r1 = fixture(:rider)
    r2 = fixture(:rider)

    assert {:ok, result} =
             Inbox.send(user, [r1.id, r2.id], "Backup riders?", save: true, name: "Backup riders")

    assert result.sent == 2
    assert result.failed == []
    [group] = Inbox.groups()
    assert group.creator.id == user.id
    assert Enum.sort(Enum.map(group.riders, & &1.id)) == Enum.sort([r1.id, r2.id])
    {:ok, view, _} = live(conn, ~p"/messages/inbox?tab=groups&context=#{group.id}&rider=#{r1.id}")
    assert has_element?(view, "#group-message-form")
    assert has_element?(view, "#new-bulk")
    refute has_element?(view, "#everyone-drawer input[name='recipients[]']")
    view |> form("#conversation-form", %{sms_message: %{body: "Only you"}}) |> render_submit()
    assert List.last(Messaging.latest_messages(r1)).body =~ "Only you"
    refute List.last(Messaging.latest_messages(r2)).body =~ "Only you"
    render_patch(view, ~p"/messages/inbox?tab=groups&context=#{group.id}&search=#{r1.name}")
    view |> form("#group-message-form", %{body: "Everyone again"}) |> render_submit()
    assert List.last(Messaging.latest_messages(r1)).body =~ "Everyone again"
    assert List.last(Messaging.latest_messages(r2)).body =~ "Everyone again"
    assert length(Inbox.groups()) == 1
    assert group.body == "Backup riders?"
    assert Repo.get!(BikeBrigade.Messaging.BulkMessageGroup, group.id).body == "Backup riders?"
  end

  test "campaigns use this week and program lead, without saving a duplicate group", %{
    conn: conn,
    user: user
  } do
    {:ok, user} = Accounts.update_user_as_admin(user, %{flags: %{"unified_messaging" => true}})
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
    assert Enum.map(Inbox.campaigns(user, true), & &1.id) == [campaign.id]
    assert other.id in Enum.map(Inbox.campaigns(user, false), & &1.id)
    {:ok, view, _} = live(conn, ~p"/messages/inbox?tab=campaigns&context=#{campaign.id}")
    refute has_element?(view, "#new-bulk")
    view |> form("#group-message-form", %{body: "Pickup moved"}) |> render_submit()
    assert Inbox.groups() == []
    assert List.last(Messaging.latest_messages(rider)).campaign_id == campaign.id
    assert List.last(Messaging.latest_messages(rider)).body =~ "Pickup moved"
  end

  test "new bulk message starts empty and uses server-owned picker state", %{
    conn: conn,
    user: user
  } do
    {:ok, _} = Accounts.update_user_as_admin(user, %{flags: %{"unified_messaging" => true}})
    rider = fixture(:rider)
    {:ok, view, _} = live(conn, ~p"/messages/inbox?tab=groups")
    view |> element("#new-bulk") |> render_click()

    view
    |> form("#inbox-bulk-form", %{body: "Hello", save_group: "false"})
    |> render_submit(%{"recipients" => [rider.id]})

    assert render(view) =~ "Select at least one rider"
    view |> element("#inbox-rider-select-input") |> render_keyup(%{"value" => rider.name})
    view |> element("[id='rider-selection:#{rider.id}'] a") |> render_click()
    view |> form("#inbox-bulk-form", %{body: "Hello", save_group: "false"}) |> render_submit()
    assert List.last(Messaging.latest_messages(rider)).body =~ "Hello"
    assert Inbox.groups() == []
  end
end
