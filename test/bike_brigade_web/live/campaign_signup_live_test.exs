defmodule BikeBrigadeWeb.CampaignSignupLiveTest do
  use BikeBrigadeWeb.ConnCase, async: false
  alias BikeBrigade.{Delivery, LocalizedDateTime, History}

  import Phoenix.LiveViewTest

  describe "Index - General" do
    setup ctx do
      program = fixture(:program, %{name: "ACME Delivery"})
      res = login_as_rider(ctx)
      Map.merge(res, %{program: program})
    end

    test "It displays the expected number of campaigns for this week", ctx do
      campaigns =
        for _n <- 1..3 do
          fixture(:campaign, %{program_id: ctx.program.id})
        end

      {:ok, live, _html} = live(ctx.conn, ~p"/campaigns/signup")

      for c <- campaigns do
        assert has_element?(live, "#campaign-#{c.id}")
      end
    end

    test "It doesn't display private campaigns", ctx do
      private_campaigns =
        for _n <- 1..3 do
          fixture(:campaign_private)
        end

      {:ok, live, _html} = live(ctx.conn, ~p"/campaigns/signup")

      for c <- private_campaigns do
        refute has_element?(live, "#campaign-#{c.id}")
      end
    end

    test "It displays a campaign in a future week", ctx do
      campaign =
        fixture(:campaign, %{
          program_id: ctx.program.id,
          delivery_start: LocalizedDateTime.now() |> DateTime.add(7, :day),
          delivery_end:
            LocalizedDateTime.now() |> DateTime.add(7, :day) |> DateTime.add(60, :second)
        })

      {:ok, live, _html} = live(ctx.conn, ~p"/campaigns/signup")
      refute has_element?(live, "#campaign-#{campaign.id}")

      week_ahead = LocalizedDateTime.now() |> Date.add(7)
      {:ok, live, _html} = live(ctx.conn, ~p"/campaigns/signup?current_week=#{week_ahead}")
      assert has_element?(live, "#campaign-#{campaign.id}")
    end

    test "It displays a campaign in a previous week; button says 'Completed'", ctx do
      campaign = make_campaign_in_past(ctx.program.id)

      fixture(:task, %{campaign: campaign, rider: nil})

      {:ok, live, _html} = live(ctx.conn, ~p"/campaigns/signup")
      refute has_element?(live, "#campaign-#{campaign.id}")

      week_ago = LocalizedDateTime.now() |> Date.add(-7)
      {:ok, live, html} = live(ctx.conn, ~p"/campaigns/signup?current_week=#{week_ago}")
      assert has_element?(live, "#campaign-#{campaign.id}")
      assert html =~ "Completed"
    end

    test "Campaigns with no tasks display correct copy", ctx do
      fixture(:campaign, %{program_id: ctx.program.id})
      {:ok, _live, html} = live(ctx.conn, ~p"/campaigns/signup")
      assert html =~ "Campaign not ready for signup"
    end
  end

  describe "Index - Campaign shows correct signup button" do
    setup ctx do
      program = fixture(:program, %{name: "ACME Delivery"})
      res = login_as_rider(ctx)
      Map.merge(res, %{program: program})
    end

    test "A campaign shows the correct filled to total tasks", ctx do
      campaign = fixture(:campaign, %{program_id: ctx.program.id})
      rider_1 = fixture(:rider, %{name: "Hannah Bannana"})
      _rider_2 = fixture(:rider, %{name: "Kiwi Stevie"})
      fixture(:task, %{campaign: campaign, rider: rider_1})
      fixture(:task, %{campaign: campaign, rider: nil})

      {:ok, _live, html} = live(ctx.conn, ~p"/campaigns/signup")

      # HACK to cleanup html with tons of whitespace.
      # Could also just use Floki to find the element and test it's there.
      normalized_html = html |> String.split() |> Enum.join(" ")
      assert normalized_html =~ "1 Available"
    end

    test "'signup' when rider hasn't signed up and there are open tasks", ctx do
      campaign = fixture(:campaign, %{program_id: ctx.program.id})
      rider_1 = fixture(:rider, %{name: "Hannah Bannana"})
      fixture(:rider, %{name: "Kiwi Stevie"})
      fixture(:task, %{campaign: campaign, rider: rider_1})
      fixture(:task, %{campaign: campaign, rider: nil})

      {:ok, _live, html} = live(ctx.conn, ~p"/campaigns/signup")
      assert html =~ "Sign up"
    end

    test "'signed up for N deliveries' if open deliveries and rider has at least one.", ctx do
      campaign = fixture(:campaign, %{program_id: ctx.program.id})
      fixture(:task, %{campaign: campaign, rider: ctx.rider})
      fixture(:task, %{campaign: campaign, rider: ctx.rider})
      fixture(:task, %{campaign: campaign, rider: nil})

      {:ok, _live, html} = live(ctx.conn, ~p"/campaigns/signup")
      assert html =~ "Signed up for 2 deliveries"
    end
  end

  describe "Index - filter by urgent campaign" do
    setup ctx do
      program = fixture(:program, %{name: "ACME Delivery"})
      res = login_as_rider(ctx)

      campaign = fixture(:campaign, %{program_id: program.id})
      campaign2 = fixture(:campaign, %{program_id: program.id})
      campaign3 = fixture(:campaign, %{program_id: program.id})

      Map.merge(res, %{
        program: program,
        campaign: campaign,
        campaign2: campaign2,
        campaign3: campaign3
      })
    end

    test "It shows urgent campaigns when called with `campaign_ids`", ctx do
      {:ok, live, html} =
        live(
          ctx.conn,
          ~p"/campaigns/signup?campaign_ids[]=#{ctx.campaign.id}&campaign_ids[]=#{ctx.campaign2.id}"
        )

      assert html =~ "These deliveries need riders in the next 48 hours:"
      assert live |> has_element?("#campaign-#{ctx.campaign.id}")
      assert live |> has_element?("#campaign-#{ctx.campaign2.id}")
      refute live |> has_element?("#campaign-#{ctx.campaign3.id}")

      # assert that only 2 campaigns - the ones who's ids we sent
      assert Floki.parse_document!(html)
             |> Floki.find(".campaign-item")
             |> Enum.count() == 2
    end
  end

  describe "Index - show opportunities (links to spreadhseet)" do
    setup ctx do
      program = fixture(:program, %{name: "ACME Delivery"})
      res = login_as_rider(ctx)
      Map.merge(res, %{program: program})
    end

    test "It displays the link to the spreadsheet", ctx do
      campaigns =
        for _n <- 1..3 do
          fixture(:campaign, %{program_id: ctx.program.id})
        end

      opportunity = fixture(:opportunity, %{program_id: ctx.program.id, published: true})

      {:ok, live, _html} = live(ctx.conn, ~p"/campaigns/signup")

      for c <- campaigns do
        assert has_element?(live, "#campaign-#{c.id}")
      end

      assert has_element?(live, ~s{[href="#{opportunity.signup_link}"]})
    end
  end

  describe "Show" do
    setup ctx do
      program = fixture(:program, %{name: "ACME Delivery"})

      res = login_as_rider(ctx)
      campaign = fixture(:campaign, %{program_id: program.id})

      task = fixture(:task, %{campaign: campaign, rider: nil, dropoff_name: "Carl Jo-Hanssen"})

      Map.merge(res, %{program: program, campaign: campaign, task: task})
    end

    test "Rider can signup for a task", ctx do
      {:ok, live, html} = live(ctx.conn, ~p"/campaigns/signup/#{ctx.campaign.id}/")
      assert html =~ "Sign up"
      refute html =~ "Unassign me"
      live |> element("#signup-btn-desktop-sign-up-task-#{ctx.task.id}") |> render_click()

      assert live |> render() =~ "Unassign me"

      # Make sure we have a log
      assert [log] = History.list_task_assignment_logs()
      assert log.action == :assigned
      assert log.task_id == ctx.task.id
      assert log.rider_id == ctx.rider.id
      assert log.user_id == ctx.user.id
    end

    test "Rider cannot signup for a task in the past", ctx do
      campaign = make_campaign_in_past(ctx.program.id)
      task = fixture(:task, %{campaign: campaign, rider: nil})

      {:ok, live, html} = live(ctx.conn, ~p"/campaigns/signup/#{campaign.id}/")

      assert html =~ "Campaign over"
      assert live |> has_element?("#signup-btn-mobile-task-over-#{task.id}")
    end

    test "Rider sees message about texting dispatch if unassigning from a campaign that's today",
         ctx do
      {:ok, live, html} = live(ctx.conn, ~p"/campaigns/signup/#{ctx.campaign.id}/")
      assert html =~ "Sign up"
      live |> element("#signup-btn-desktop-sign-up-task-#{ctx.task.id}") |> render_click()

      html = live |> render()
      assert html =~ "Unassign me"

      assert html =~
               "This delivery starts today. If you need to unassign yourself, please also text dispatch to let us know!"

      campaign = make_campaign_in_future(ctx.program.id)
      task = fixture(:task, %{campaign: campaign, rider: nil})

      {:ok, live, _html} = live(ctx.conn, ~p"/campaigns/signup/#{campaign.id}/")

      live |> element("#signup-btn-desktop-sign-up-task-#{task.id}") |> render_click()

      html = live |> render()
      assert html =~ "Unassign me"

      refute html =~
               "This delivery starts today. If you need to unassign yourself, please also text dispatch to let us know!"
    end

    test "we see pertinent task information", ctx do
      {:ok, live, html} = live(ctx.conn, ~p"/campaigns/signup/#{ctx.campaign.id}/")

      # we only show the first initials of the dropoff name, which is Carl Jo-Hansen -> CJH
      refute html =~ ctx.task.dropoff_name

      assert live |> element("[data-test-id=dropoff-name-#{ctx.task.id}]") |> render =~ "CJH"
      assert html =~ BikeBrigade.Locations.neighborhood(ctx.task.dropoff_location)

      # We show the name and description of the item
      assert html =~ "Burrito"
      assert html =~ "a large burrito with all the fixings"
    end

    test "we see campaign photos and description if available", ctx do
      {:ok, _live, html} = live(ctx.conn, ~p"/campaigns/signup/#{ctx.campaign.id}/")
      refute html =~ "Delivery photos"

      Delivery.update_program(ctx.program, %{
        photos: ["https://example.com/photo.jpg"],
        photo_description: "a typical meal"
      })

      {:ok, _live, html} = live(ctx.conn, ~p"/campaigns/signup/#{ctx.campaign.id}/")
      assert html =~ "Delivery photos"
      assert html =~ "https://example.com/photo.jpg"
      assert html =~ "a typical meal"
    end

    test "Invalid route for campaign shows flash and redirects", ctx do
      assert {:error,
              {:redirect,
               %{flash: %{"error" => "Invalid campaign id."}, to: "/campaigns/signup/"}}} =
               live(ctx.conn, ~p"/campaigns/signup/foo/")
    end

    test "Invalid route for unpulished campaign", ctx do
      campaign = fixture(:campaign_private)

      assert {:error,
              {:redirect,
               %{flash: %{"error" => "Invalid campaign id."}, to: "/campaigns/signup/"}}} =
               live(ctx.conn, ~p"/campaigns/signup/#{campaign.id}/")
    end

    test "Invalid route for campaign-task shows flash and redirects", ctx do
      res = live(ctx.conn, ~p"/campaigns/signup/#{ctx.campaign.id}/task/foo")
      assert {:error, {:redirect, %{flash: %{"error" => "Invalid task id."}, to: _}}} = res
    end

    test "Rider can unassign themselves", ctx do
      task = fixture(:task, %{campaign: ctx.campaign, rider: ctx.rider})
      {:ok, live, html} = live(ctx.conn, ~p"/campaigns/signup/#{ctx.campaign.id}")
      assert html =~ "Unassign me"
      element(live, "a#signup-btn-desktop-unassign-task-#{task.id}") |> render_click()
      refute render(live) =~ "Unassign me"

      # Make sure we have a log
      assert [log] = History.list_task_assignment_logs()
      assert log.action == :unassigned
      assert log.task_id == task.id
      assert log.rider_id == ctx.rider.id
      assert log.user_id == ctx.user.id
    end
  end

  defp make_campaign_in_past(program_id) do
    fixture(:campaign, %{
      program_id: program_id,
      delivery_start: LocalizedDateTime.now() |> DateTime.add(-7, :day),
      delivery_end: LocalizedDateTime.now() |> DateTime.add(-7, :day) |> DateTime.add(60, :second)
    })
  end

  defp make_campaign_in_future(program_id) do
    fixture(:campaign, %{
      program_id: program_id,
      delivery_start: LocalizedDateTime.now() |> DateTime.add(7, :day),
      delivery_end: LocalizedDateTime.now() |> DateTime.add(7, :day) |> DateTime.add(60, :second)
    })
  end
end
