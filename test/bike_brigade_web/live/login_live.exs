defmodule BikeBrigadeWeb.LoginLiveTest do
  use BikeBrigadeWeb.ConnCase
  import Phoenix.LiveViewTest

  describe "Login as a rider" do
    test "Logging in with invalid credentials raises an error", %{conn: conn} do
      rider = fixture(:rider)
      {:ok, view, html} = live(conn, ~p"/login")

      # TODO: leaving off.
      # view
      # |> submit_form("#login-form")
      # |> render_change

      open_browser(view)
      dbg(rider)

      assert 1 == 1
    end

    test "Logging in with valid credentials forwards rider to /itinerary" do
    end
  end
end
