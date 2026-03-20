defmodule BikeBrigadeWeb.RiderLiveTest do
  use BikeBrigadeWeb.ConnCase

  import Phoenix.LiveViewTest

  alias BikeBrigade.Riders

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
      {:ok, index_live, _html} = live(conn, ~p"/riders")

      html =
        index_live
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

    test "Logged in rider can see their capacity", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/profile")
      assert html =~ "dispatch-data-capacity"
    end
  end

  describe "Edit: rider logged-in" do
    setup [:create_rider, :login_as_rider]

    test "Logged in rider cannot see dispatch-specific fields in slideover", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/profile/edit")
      refute html =~ "Send text-only delivery instructions"
      refute html =~ "Flags"
      refute html =~ "Last Safety Check"
      refute html =~ "Notes (internal)"
    end

    test "Logged in rider can edit their profile.", %{conn: conn, rider: rider} do
      {:ok, view, html} = live(conn, ~p"/profile/edit")
      assert html =~ rider.name

      view
      |> form("#rider-form", rider_form: %{"name" => "alex123"})
      |> render_submit()

      flash = assert_redirected(view, "/profile")
      assert flash["info"] == "Rider updated successfully"

      {:ok, _view, html} = live(conn, ~p"/profile")
      assert html =~ "alex123"
    end

    test "Logged in rider cannot edit admin fields.", %{conn: conn, rider: rider} do
      {:ok, view, html} = live(conn, ~p"/profile/edit")
      assert html =~ rider.name
      error_msg_regex = ~r/could not find non-disabled input, select or textarea/

      assert_raise ArgumentError, error_msg_regex, fn ->
        view
        |> form("#rider-form", rider_form: %{"internal_notes" => "notes!"})
        |> render_submit()
      end

      assert_raise ArgumentError, error_msg_regex, fn ->
        view
        |> form("#rider-form", rider_form: %{"last_safety_check" => "2023-11-21"})
        |> render_submit()
      end

      assert_raise ArgumentError, error_msg_regex, fn ->
        view
        |> form("#rider-form", rider_form: %{"text_based_itinerary" => "false"})
        |> render_submit()
      end

      assert_raise ArgumentError, error_msg_regex, fn ->
        view
        |> form("#rider-form", rider_form: %{"tags" => ["foo"]})
        |> render_submit()
      end
    end
  end

  describe "Show: Dispatch logged-in" do
    setup [:create_rider, :login]

    test "shows rider", %{conn: conn, rider: rider} do
      {:ok, _view, html} = live(conn, ~p"/riders/#{rider}")

      assert html =~ rider.name
      assert html =~ rider.location.address
      assert html =~ "dispatch-data-capacity"
    end

    test "Logged in dispatcher can edit admin-only fields.", %{conn: conn, rider: rider} do
      {:ok, view, html} = live(conn, ~p"/riders/#{rider}/show/edit")
      assert html =~ rider.name

      view
      |> form("#rider-form",
        rider_form: %{
          "name" => "alex123",
          "internal_notes" => "notes!",
          "last_safety_check" => "2023-11-21",
          "text_based_itinerary" => "false"
        }
      )
      |> render_submit()
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

  describe "Tag visibility on profile: dispatcher" do
    setup [:create_rider, :login]

    test "dispatcher can see all tags including restricted on rider profile", %{
      conn: conn,
      rider: rider
    } do
      normal_tag = fixture(:tag, %{name: "Normal Tag", restricted: false})
      restricted_tag = fixture(:tag, %{name: "Restricted Tag", restricted: true})

      rider = rider |> BikeBrigade.Repo.preload(:tags)
      {:ok, _} = Riders.update_rider_with_tags(rider, %{}, [normal_tag.name, restricted_tag.name])

      {:ok, _view, html} = live(conn, ~p"/riders/#{rider}")

      assert html =~ "Normal Tag"
      assert html =~ "Restricted Tag"
    end

    test "dispatcher can see restricted tags in edit form", %{conn: conn, rider: rider} do
      _restricted_tag = fixture(:tag, %{name: "Admin Only Tag", restricted: true})

      {:ok, _view, html} = live(conn, ~p"/riders/#{rider}/show/edit")

      # Should see the restricted tag as an available option
      assert html =~ "Admin Only Tag"
    end
  end

  describe "Tag visibility on profile: rider" do
    setup [:create_rider, :login_as_rider]

    test "rider cannot see restricted tags on their profile", %{conn: conn, rider: rider} do
      normal_tag = fixture(:tag, %{name: "Visible Tag", restricted: false})
      restricted_tag = fixture(:tag, %{name: "Hidden Tag", restricted: true})

      rider = rider |> BikeBrigade.Repo.preload(:tags)
      {:ok, _} = Riders.update_rider_with_tags(rider, %{}, [normal_tag.name, restricted_tag.name])

      {:ok, _view, html} = live(conn, ~p"/profile")

      assert html =~ "Visible Tag"
      refute html =~ "Hidden Tag"
    end

    test "rider cannot see restricted tags in edit form", %{conn: conn} do
      _normal_tag = fixture(:tag, %{name: "Public Tag", restricted: false})
      _restricted_tag = fixture(:tag, %{name: "Secret Tag", restricted: true})

      {:ok, _view, html} = live(conn, ~p"/profile/edit")

      assert html =~ "Public Tag"
      refute html =~ "Secret Tag"
    end
  end
end
