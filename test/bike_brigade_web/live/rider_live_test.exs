defmodule BikeBrigadeWeb.RiderLiveTest do
  use BikeBrigadeWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "Index" do
    setup [:create_rider, :login]

    test "lists all riders", %{conn: conn, rider: rider} do
      {:ok, _index_live, html} = live(conn, Routes.rider_index_path(conn, :index))

      assert html =~ "Riders"
      assert html =~ rider.name
    end

    test "select riders", %{conn: conn, rider: rider} do
      {:ok, view, _html} = live(conn, Routes.rider_index_path(conn, :index))

      # Select the rider
      assert view
             |> element("#rider-list-#{rider.id} a")
             |> render_click() =~ rider.email

      # Unselect the rider
      refute view
             |> element("#rider-list-#{rider.id} a")
             |> render_click() =~ rider.email
    end

    test "edit riders", %{conn: conn, rider: rider} do
      {:ok, view, _html} = live(conn, Routes.rider_index_path(conn, :index))

      # Select the rider
      assert view
             |> element("#rider-list-#{rider.id} a")
             |> render_click() =~ rider.email

      # click edit
      view
      |> element("#rider-#{rider.id} a", "Edit")
      |> render_click()

      assert_patched(view, "/riders/#{rider.id}/edit")

      # Change the rider's name
      view
      |> element("form#rider-form")
      |> render_submit(%{name: "New Name"})

      flash = assert_redirected(view, "/riders")
      assert flash["info"] == "Rider updated successfully"
    end
  end
end
