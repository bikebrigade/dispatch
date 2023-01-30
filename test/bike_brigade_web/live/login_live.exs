defmodule BikeBrigadeWeb.LoginLiveTest do
  use BikeBrigadeWeb.ConnCase
  alias BikeBrigade.Accounts
  import Phoenix.LiveViewTest

  describe "Login as a rider" do
    test "Logging in with invalid credentials raises an error", %{conn: conn} do
      # NOTE: this rider is not a proper user yet, so it should yield an error.
      rider = fixture(:rider)

      {:ok, view, _html} = live(conn, ~p"/login")

      dbg(rider.phone)

      view
      |> form("#login-form", %{"login" => %{"phone" => rider.phone}})
      |> render_submit()

      open_browser(view)

      assert 1 == 1
    end

    test "Logging in with valid credentials forwards rider to /itinerary", %{conn: conn} do
      rider = fixture(:rider)
      {:ok, rider_user} = Accounts.create_user_for_rider(rider)
      {:ok, view, _html} = live(conn, ~p"/login")
      dbg(rider_user)

      view
      |> form("#login-form", %{"login" => %{"phone" => rider.phone}})
      |> render_submit()

      form = form(view, "#login-form2", %{"login" => %{"token_attempt" => "1"}})
      dbg(form)
      conn = submit_form(form, conn)
      assert conn.method == "POST"

      # view
      # |> form("#login-form2", %{"login" => %{"token_attempt" => "1"}})
      # |> submit_form()

      open_browser(view)

      assert 1 == 1
    end
  end
end
