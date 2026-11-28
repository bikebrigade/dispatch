defmodule BikeBrigadeWeb.AuthenticationControllerTest do
  use BikeBrigadeWeb.ConnCase
  alias BikeBrigade.Accounts

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

    test "logs in and out with CSRF protection enabled", %{conn: conn, user: user} do
      conn = conn |> enable_csrf_protection() |> get(~p"/login")
      login_csrf_token = csrf_token(conn)

      conn =
        conn
        |> recycle()
        |> enable_csrf_protection()
        |> post(~p"/login", %{_csrf_token: login_csrf_token, login: %{phone: user.phone}})

      token = Map.fetch!(BikeBrigade.AuthenticationMessenger.get_state(), user.phone)
      token_csrf = csrf_token(conn)

      conn =
        conn
        |> recycle()
        |> enable_csrf_protection()
        |> post(~p"/login", %{
          _csrf_token: token_csrf,
          login: %{phone: user.phone, token_attempt: token}
        })

      assert redirected_to(conn) == ~p"/"
      assert get_session(conn, :user_id) == user.id

      conn = conn |> recycle() |> enable_csrf_protection() |> get(~p"/home")
      logout_csrf_token = csrf_token(conn)
      assert logout_csrf_token != login_csrf_token

      conn =
        conn
        |> recycle()
        |> enable_csrf_protection()
        |> delete(~p"/logout", %{_csrf_token: logout_csrf_token})

      assert redirected_to(conn) == ~p"/login"
      refute get_session(conn, :user_id)
    end

    test "a stale login form returns to a fresh login page without consuming the code", %{
      conn: conn,
      user: user
    } do
      conn = post(conn, ~p"/login", %{login: %{phone: user.phone}})
      stale_csrf_token = csrf_token(conn)
      token = Map.fetch!(BikeBrigade.AuthenticationMessenger.get_state(), user.phone)

      # The form can outlive its session cookie (expiry or a login/logout in another tab).
      conn =
        build_conn()
        |> enable_csrf_protection()
        |> post(~p"/login", %{
          _csrf_token: stale_csrf_token,
          login: %{phone: user.phone, token_attempt: token}
        })

      assert redirected_to(conn, 303) == ~p"/login"
      refute get_session(conn, :user_id)
      assert Map.fetch!(BikeBrigade.AuthenticationMessenger.get_state(), user.phone) == token

      conn = conn |> recycle() |> enable_csrf_protection() |> get(~p"/login")
      assert html_response(conn, 200) =~ "Your login page expired. Please try again."
      assert csrf_token(conn) != stale_csrf_token
    end

    test "other forms still reject invalid CSRF tokens", %{conn: conn, user: user} do
      conn = conn |> login_user(user) |> enable_csrf_protection()

      assert_error_sent 403, fn ->
        delete(conn, ~p"/logout", %{_csrf_token: "invalid"})
      end
    end

    test "a stale login submission preserves a session authenticated in another tab", %{
      conn: conn,
      user: user
    } do
      conn =
        conn
        |> login_user(user)
        |> enable_csrf_protection()
        |> post(~p"/login", %{
          _csrf_token: "stale-token",
          login: %{phone: user.phone, token_attempt: "000000"}
        })

      assert redirected_to(conn, 303) == ~p"/login"
      assert get_session(conn, :user_id) == user.id

      conn = conn |> recycle() |> enable_csrf_protection() |> get(~p"/login")
      assert redirected_to(conn) == ~p"/"
    end

    test "lets you cancel a login", %{conn: conn, user: user} do
      conn = post(conn, ~p"/login", %{login: %{phone: user.phone}})
      conn = delete(conn, ~p"/login", %{phone: user.phone})
      assert redirected_to(conn) == ~p"/login"
      assert Map.get(BikeBrigade.AuthenticationMessenger.get_state(), user.phone) == nil
    end
  end

  defp enable_csrf_protection(conn) do
    put_private(conn, :plug_skip_csrf_protection, false)
  end

  defp csrf_token(conn) do
    conn
    |> html_response(200)
    |> Floki.parse_document!()
    |> Floki.find("meta[name=csrf-token]")
    |> Floki.attribute("content")
    |> hd()
  end
end
