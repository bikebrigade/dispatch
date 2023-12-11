defmodule BikeBrigadeWeb.CampaignSignupLiveTest do
  use BikeBrigadeWeb.ConnCase, only: []

  import Phoenix.LiveViewTest

  @week_in_sec 604_900

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

    test "It displays a campaign in a future week", ctx do
      campaign =
        fixture(:campaign, %{
          program_id: ctx.program.id,
          delivery_start: DateTime.utc_now() |> DateTime.add(@week_in_sec),
          delivery_end:
            DateTime.utc_now() |> DateTime.add(@week_in_sec) |> DateTime.add(60, :second)
        })

      {:ok, live, _html} = live(ctx.conn, ~p"/campaigns/signup")
      refute has_element?(live, "#campaign-#{campaign.id}")

      week_ahead = Date.utc_today() |> Date.add(7)
      {:ok, live, _html} = live(ctx.conn, ~p"/campaigns/signup?current_week=#{week_ahead}")
      assert has_element?(live, "#campaign-#{campaign.id}")
    end

    test "It displays a campaign in a previous week; button says 'Completed'", ctx do
      campaign =
        fixture(:campaign, %{
          program_id: ctx.program.id,
          delivery_start: DateTime.utc_now() |> DateTime.add(-@week_in_sec),
          delivery_end:
            DateTime.utc_now() |> DateTime.add(-@week_in_sec) |> DateTime.add(60, :second)
        })

      {:ok, live, _html} = live(ctx.conn, ~p"/campaigns/signup")
      refute has_element?(live, "#campaign-#{campaign.id}")

      week_ago = Date.utc_today() |> Date.add(-7)
      {:ok, live, html} = live(ctx.conn, ~p"/campaigns/signup?current_week=#{week_ago}")
      assert has_element?(live, "#campaign-#{campaign.id}")
      assert html =~ "Completed"
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
      assert normalized_html =~ "1 / 2 Tasks filled"
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

  describe "Show" do
    setup ctx do
      program = fixture(:program, %{name: "ACME Delivery"})

      res = login_as_rider(ctx)
      campaign = fixture(:campaign, %{program_id: program.id})

      tasks = [
        fixture(:task, %{campaign: campaign, rider: res.rider}),
        fixture(:task, %{campaign: campaign, rider: nil}),
        fixture(:task, %{campaign: campaign, rider: nil})
      ]

      Map.merge(res, %{program: program, campaign: campaign, tasks: tasks})
    end

    test "we can signup for a task", ctx do
      {:ok, _live, html} = live(ctx.conn, ~p"/campaigns/signup/#{ctx.campaign.id}/")

      # click on first task's Signup button"
      # confirm we navigate to new route
      # confirm we can render submit
      # confirm we can revisit the route and that "unassign me" is present on the same task id btn.

    end

    test "we see pertinent task information", ctx do
      {:ok, _live, html} = live(ctx.conn, ~p"/campaigns/signup/#{ctx.campaign.id}/")

      for t <- ctx.tasks do
        assert html =~ t.dropoff_name
        assert html =~ t.dropoff_location.address
      end
    end

    test "Invalid route for task shows flash and redirects", ctx do
      assert {:error,
              {:redirect,
               %{flash: %{"error" => "Invalid campaign id."}, to: "/campaigns/signup/"}}} =
               live(ctx.conn, ~p"/campaigns/signup/foo/")
    end

    test "Ride can unassign themselves", ctx do
      {:ok, live, html} = live(ctx.conn, ~p"/campaigns/signup/#{ctx.campaign.id}")
      assert html =~ "Unassign me"
      element(live, "a", "Unassign me") |> render_click()
      refute render(live) =~ "Unassign me"
    end
  end
end
