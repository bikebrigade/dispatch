defmodule BikeBrigadeWeb.AuthenticationControllerTest do
  use BikeBrigadeWeb.ConnCase
  alias BikeBrigade.{Accounts, AuthenticationMessenger}

  describe "login" do
    setup do
      rider = fixture(:rider)
      {:ok, user} = Accounts.create_user_for_rider(rider)

      %{user: user}
    end

    test "shows the login page", %{conn: conn} do
      conn = get(conn, ~p"/login")
      assert html_response(conn, 200) =~ "Sign into your Bike Brigade account"
    end

    test "errors when you send an invalid  number", %{conn: conn} do
      conn = post(conn, ~p"/login", %{login: %{phone: "5555555555555555"}})
      assert html_response(conn, 200) =~ "phone number is not valid for Canada"
    end

    test "errors when you send a number that doesn't exist", %{conn: conn} do
      conn = post(conn, ~p"/login", %{login: %{phone: "6475555555"}})

      assert html_response(conn, 200) =~
               "We can&#39;t find your number. Have you signed up for Bike Brigade?"
    end

    test "shows the token page when you give a valid number", %{conn: conn, user: user} do
      conn = post(conn, ~p"/login", %{login: %{phone: user.phone}})
      assert html_response(conn, 200) =~ "We sent an authentication code to your phone number"
    end

    test "errors when you send an invalid token", %{conn: conn, user: user} do
      conn = post(conn, ~p"/login", %{login: %{phone: user.phone}})

      token = Map.get(BikeBrigade.AuthenticationMessenger.get_state(), user.phone)
      conn = post(conn, ~p"/login", %{login: %{phone: user.phone, token_attempt: "not a token"}})

      assert redirected_to(conn) == ~p"/login?login[phone]=#{user.phone}"
      conn = get(conn, ~p"/login?login[phone]=#{user.phone}")
      assert html_response(conn, 200) =~ "Access code is invalid. Please try again."

      # Token is not regenerated after error
      assert Map.get(BikeBrigade.AuthenticationMessenger.get_state(), user.phone) == token
    end

    test "logs you in with valid token", %{conn: conn, user: user} do
      conn = post(conn, ~p"/login", %{login: %{phone: user.phone}})
      token = Map.get(BikeBrigade.AuthenticationMessenger.get_state(), user.phone)
      conn = post(conn, ~p"/login", %{login: %{phone: user.phone, token_attempt: token}})
      assert redirected_to(conn) == ~p"/"

      conn = get(conn, ~p"/home")
      assert html_response(conn, 200) =~ "Welcome!"
    end
  end
end
