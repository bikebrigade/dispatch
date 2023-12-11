defmodule BikeBrigadeWeb.CampaignSignupLiveTest do
  use BikeBrigadeWeb.ConnCase, only: []

  import Phoenix.LiveViewTest
  # alias BikeBrigadeWeb.CampaignHelpers
  # alias BikeBrigade.LocalizedDateTime
  #
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

    test "It displays a campaign in a previous week", ctx do
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
      {:ok, live, _html} = live(ctx.conn, ~p"/campaigns/signup?current_week=#{week_ago}")
      assert has_element?(live, "#campaign-#{campaign.id}")
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

    test "'completed' and cannot be clicked when a campaign is in the past" do
    end
  end

  describe "Show" do
    test "Signup flow works" do
    end

    test "Invalid route for task shows flash" do
    end

    test "Ride can unassign themselves" do
    end
  end
end
