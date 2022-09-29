defmodule BikeBrigadeWeb.RiderLiveTest do
  use BikeBrigadeWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "Index" do
    setup [:create_rider, :login]

    test "lists all riders", %{conn: conn, rider: rider} do
      {:ok, _index_live, html} = live(conn, ~p"/riders")

      assert html =~ "Riders"
      assert html =~ rider.name
    end

    test "bulk message with no riders selected", %{conn: conn, rider: rider} do
      {:ok, view, _html} = live(conn, ~p"/riders")

      view
      |> element(" a", "Bulk Message")
      |> render_click()

      refute view
             |> element("#bulk_message")
             |> render() =~ rider.name
    end

    test "bulk message with rider selected", %{conn: conn, rider: rider} do
      {:ok, view, _html} = live(conn, ~p"/riders")

      view
      |> form("#selected")
      |> render_change(%{_target: ["selected", rider.id], selected: %{rider.id => true}})

      view
      |> element(" a", "Bulk Message")
      |> render_click()

      assert view
             |> element("#bulk_message")
             |> render() =~ rider.name
    end

    test "show rider", %{conn: conn, rider: rider} do
      {:ok, view, _html} = live(conn, ~p"/riders")

      view
      |> element("#riders a", rider.name)
      |> render_click()

      assert_redirected(view, "/riders/#{rider.id}")
    end
  end

  describe "Show" do
    setup [:create_rider, :login]

    test "shows rider", %{conn: conn, rider: rider} do
      {:ok, _view, html} = live(conn, ~p"/riders/#{rider}")

      assert html =~ rider.name
      assert html =~ rider.location.address
    end

    test "edit rider", %{conn: conn, rider: rider} do
      {:ok, view, _html} = live(conn, ~p"/riders/#{rider}/show/edit")

      view
      |> element("form#rider-form")
      |> render_submit(%{name: "New Name"})

      flash = assert_redirected(view, "/riders/#{rider.id}")
      assert flash["info"] == "Rider updated successfully"
    end
  end
end
