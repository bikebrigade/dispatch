defmodule BikeBrigadeWeb.RiderLiveTest do
  use BikeBrigadeWeb.ConnCase

  alias BikeBrigade.Accounts

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

    test "Doesn't have erorr when user has a rider", %{conn: conn, user: user, rider: rider} do
      # Associate the user with a rider
      # In the future the fixture may do this for us
      {:ok, user} = Accounts.update_user_as_admin(user, %{rider_id: rider.id})

      # Make sure we actually have a rider
      assert user.rider_id != nil

      {:ok, _index_live, html} = live(conn, Routes.itinerary_index_path(conn, :index))

      assert html =~ "Itinerary"
      refute html =~ "User is not associated with a rider!"
    end
  end
end
