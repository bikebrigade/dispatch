defmodule BikeBrigadeWeb.RiderLiveTest do
  use BikeBrigadeWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "Index" do
    setup [:create_rider, :login]

    test "lists all riders, with working next/previous pagination", %{conn: conn} do
      for _ <- 0..25, do: fixture(:rider)
      {:ok, index_live, _html} = live(conn, ~p"/riders")

      get_row_count = fn view ->
        view |> render() |> Floki.parse_fragment!() |> Floki.find(".rider-row") |> Enum.count()
      end

      assert get_row_count.(index_live) == 20
      index_live |> element("#next-riders-page") |> render_click()
      assert get_row_count.(index_live) == 7
      index_live |> element("#prev-riders-page") |> render_click()
      assert get_row_count.(index_live) == 20
    end

    test "searching riders works", %{conn: conn} do
      fixture(:rider, %{name: "Béa"})
      {:ok, index_live, html} = live(conn, ~p"/riders")

      html = index_live
      |> element("#rider-search")
      |> render_submit(%{value: "Bea"})

      assert Floki.parse_fragment!(html) |> Floki.find(".rider-row") |> Enum.count() == 1
      assert html =~ "Béa"

    end

    test "bulk message with no riders selected", %{conn: conn, rider: rider} do
      {:ok, view, _html} = live(conn, ~p"/riders")

      view
      |> element(" a", "Bulk Message")
      |> render_click()

      refute view
             |> element("#sms_message-form")
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
             |> element("#sms_message-form")
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

  describe "Show: rider logged-in" do
    setup [:create_rider, :login_as_rider]

    test "Logged in rider cannot see their tag or capacity", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/profile")
      refute html =~ "dispatch-data-tags-and-capacity"
    end
  end

  describe "Edit: rider logged-in" do
    setup [:create_rider, :login_as_rider]

    test "Logged in rider cannot dispatch specific fields in slideover", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/profile/edit")
      refute html =~ "Send text-only delivery instructions"
      refute html =~ "Flags"
      refute html =~ "Last Safety Check"
      refute html =~ "Notes (internal)"
    end
  end

  describe "Show: Dispatch logged-in" do
    setup [:create_rider, :login]

    test "shows rider", %{conn: conn, rider: rider} do
      {:ok, _view, html} = live(conn, ~p"/riders/#{rider}")

      assert html =~ rider.name
      assert html =~ rider.location.address
      assert html =~ "dispatch-data-tags-and-capacity"
    end


    test "edit rider", %{conn: conn, rider: rider} do
      {:ok, view, _html} = live(conn, ~p"/riders/#{rider}/show/edit")

      view
      |> element("form#rider-form")
      |> render_submit(%{name: "New Name"})

      flash = assert_redirected(view, "/riders/#{rider.id}")
      assert flash["info"] == "Rider updated successfully"
    end

    test "Logged in dispatcher can see dispatch-specific fields", %{conn: conn, rider: rider} do
      {:ok, _view, html} = live(conn, ~p"/riders/#{rider.id}/show/edit")
      assert html =~ "Send text-only delivery instructions"
      assert html =~ "Flags"
      assert html =~ "Last Safety Check"
      assert html =~ "Notes (internal)"
    end
  end
end
