defmodule BikeBrigadeWeb.StatsLive.LeaderboardTest do
  use BikeBrigadeWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "Leaderboard, seen as a rider" do
    setup [:create_campaign_with_riders_with_tasks, :login_as_rider]

    test "Rider's who aren't dispatchers cannot see the 'Show All Riders' button", %{conn: conn} do
      {:ok, leaderboard_live, _html} = live(conn, ~p"/leaderboard")

      assert render(leaderboard_live)
             |> Floki.find("td")
             |> Enum.filter(fn f -> Floki.text(f) == "Anonymous" end)
             |> length() == 7

      refute leaderboard_live |> element("a", "Show All Riders") |> has_element?()
    end
  end

  describe "Leaderboard, seen as a rider who is also a dispatcher" do
    setup [:create_campaign_with_riders_with_tasks, :login_as_rider_and_dispatcher]

    test "can see the 'Show All Riders' button", %{conn: conn} do
      {:ok, leaderboard_live, _html} = live(conn, ~p"/leaderboard")
      assert leaderboard_live |> element("a", "Show All Riders") |> has_element?()
    end

    test "Toggling the button will deanonymoize all riders'", %{conn: conn} do
      {:ok, leaderboard_live, _html} = live(conn, ~p"/leaderboard")

      assert render(leaderboard_live)
             |> Floki.find("td")
             |> Enum.filter(fn f -> Floki.text(f) == "Anonymous" end)
             |> length() == 7

      leaderboard_live |> element("a", "Show All Riders") |> render_click()

      assert render(leaderboard_live)
             |> Floki.find("td")
             |> Enum.filter(fn f -> Floki.text(f) == "Anonymous" end)
             |> length() == 0
    end
  end
end
