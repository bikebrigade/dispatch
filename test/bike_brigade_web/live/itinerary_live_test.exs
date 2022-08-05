defmodule BikeBrigadeWeb.RiderLiveTest do
  use BikeBrigadeWeb.ConnCase

  alias BikeBrigade.Accounts
  alias BikeBrigade.LocalizedDateTime

  import Phoenix.LiveViewTest

  describe "Index" do
    setup [:create_rider, :login]

    test "Displays error when user has no rider", %{conn: conn, user: user} do
      # Make sure we actually don't have a rider
      assert user.rider_id == nil

      {:ok, _index_live, html} = live(conn, Routes.itinerary_index_path(conn, :index))

      assert html =~ "Itinerary"
      assert html =~ "User is not associated with a rider!"
    end

    test "Doesn't have error when user has a rider", %{conn: conn, user: user, rider: rider} do
      # Associate the user with a rider
      # In the future the fixture may do this for us
      {:ok, user} = Accounts.update_user_as_admin(user, %{rider_id: rider.id})

      # Make sure we actually have a rider
      assert user.rider_id != nil

      {:ok, _index_live, html} = live(conn, Routes.itinerary_index_path(conn, :index))

      assert html =~ "Itinerary"
      refute html =~ "User is not associated with a rider!"
    end

    test "No campaigns for today's date", %{conn: conn, user: user, rider: rider} do
      # Associate the user with a rider
      # In the future the fixture may do this for us
      {:ok, user} = Accounts.update_user_as_admin(user, %{rider_id: rider.id})

      # Make sure we actually have a rider
      assert user.rider_id != nil

      {:ok, _index_live, html} = live(conn, Routes.itinerary_index_path(conn, :index))

      assert html =~ "Itinerary"
      assert html =~ Calendar.strftime(LocalizedDateTime.today(), "%A %B %-d, %Y")
      assert html =~ "No campaigns found for this day."
    end

    test "Go to previous day", %{conn: conn, user: user, rider: rider} do
      # Associate the user with a rider
      # In the future the fixture may do this for us
      {:ok, user} = Accounts.update_user_as_admin(user, %{rider_id: rider.id})

      # Make sure we actually have a rider
      assert user.rider_id != nil

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
