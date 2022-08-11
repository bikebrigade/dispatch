defmodule BikeBrigadeWeb.RiderLiveTest do
  use BikeBrigadeWeb.ConnCase

  alias BikeBrigade.LocalizedDateTime

  import Phoenix.LiveViewTest

  describe "Itinerary for User without associated Rider" do
    setup [:login]

    test "Displays error when user has no rider", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, Routes.itinerary_index_path(conn, :index))

      assert html =~ "Itinerary"
      assert html =~ "User is not associated with a rider!"
    end
  end

  describe "Itinerary for User with associated Rider" do
    setup [:login_as_rider]

    test "doesn't show an error", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, Routes.itinerary_index_path(conn, :index))

      assert html =~ "Itinerary"
      refute html =~ "User is not associated with a rider!"
    end

    test "shows days without campaigns", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, Routes.itinerary_index_path(conn, :index))

      assert html =~ "Itinerary"
      assert html =~ Calendar.strftime(LocalizedDateTime.today(), "%A %B %-d, %Y")
      assert html =~ "No campaigns found for this day."
    end

    test "can go to previous day", %{conn: conn} do
      {:ok, view, html} = live(conn, Routes.itinerary_index_path(conn, :index))

      assert html =~ "Itinerary"

      html =
        view
        |> element("[aria-label='Previous Day']")
        |> render_click()

      previous_day = Date.add(LocalizedDateTime.today(), -1)

      assert html =~ Calendar.strftime(previous_day, "%A %B %-d, %Y")
    end
  end
end
