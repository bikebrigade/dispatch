defmodule BikeBrigadeWeb.StatsLive.LeaderboardTest do
  use BikeBrigadeWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "Leaderboard, seen as a rider" do
    # TODO: create a campaign, with tasks, assign a rider to it, view stats
    setup [:create_campaign_with_riders, :login_as_rider]

    test "Rider's who aren't dispatchers cannot see the 'Show All Riders' button", %{conn: conn} do
      # {:ok, leaderboard_live, html} = live(conn, ~p"/leaderboard")
      {:ok, leaderboard_live, _html} = live(conn, ~p"/leaderboard")
      # open_browser(leaderboard_live)
      refute leaderboard_live |> element("a", "Show All Riders") |> has_element?()
    end

    # test "Clicking the 'Show All Riders' button toggles anonymity in the rider list" do
    # end
  end

  describe "Leaderboard, seen as a rider who is also a dispatcher" do
    # TODO: create a campaign, with tasks, assign a rider to it, view stats
    # TODO: this dispatcher isn't also a rider.
    setup [:create_campaign_with_riders, :login]

    test "Rider's who aren't dispatchers cannot see the 'Show All Riders' button", %{conn: conn} do
      {:ok, leaderboard_live, _html} = live(conn, ~p"/leaderboard")
      open_browser(leaderboard_live)
      assert leaderboard_live |> element("a", "Show All Riders") |> has_element?()
    end

    # test "Clicking the 'Show All Riders' button toggles anonymity in the rider list" do
    # end
  end
end
