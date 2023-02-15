defmodule BikeBrigadeWeb.LoginLiveTest do
  use BikeBrigadeWeb.ConnCase

  alias BikeBrigade.SmsService.FakeSmsService

  import Phoenix.LiveViewTest

  describe "Log in page" do
    test "renders log in page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/login")

      assert html =~ "Sign into your Bike Brigade account"
      assert html =~ "Sign Up!"
      assert html =~ "Need help? Email"
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> login_user(fixture(:user))
        |> live(~p"/login")
        |> follow_redirect(conn, "/")

      assert {:ok, _conn} = result
    end
  end

  describe "user login" do
    test "shows the login page with an error if the phone is unregistered", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/login")

      result =
        lv
        |> form("#login-form", login: %{phone: "+16475555555"})
        |> render_submit()

      assert result =~ "We can&#39;t find your number. Have you signed up for Bike Brigade?"
    end

    test "redirects to the login page with a flash error if the token is invalid", %{
      conn: conn
    } do
      user = fixture(:user)
      {:ok, lv, _html} = live(conn, ~p"/login")

      result =
        lv
        |> form("#login-form", login: %{phone: user.phone})
        |> render_submit()

      assert result =~ "We sent an authentication code to your phone number"

      form = form(lv, "#login-form2", login: %{phone: user.phone, token_attempt: "not a token"})
      conn = submit_form(form, conn)

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "Access code is invalid. Please try again."

      assert redirected_to(conn) == ~p"/login?phone=#{user.phone}"
    end

    test "redirects if user logins with valid credentials", %{conn: conn} do
      user = fixture(:user)
      {:ok, lv, _html} = live(conn, ~p"/login")

      result =
        lv
        |> form("#login-form", login: %{phone: user.phone})
        |> render_submit()

      assert result =~ "We sent an authentication code to your phone number"

      form =
        form(lv, "#login-form2",
          login: %{phone: user.phone, token_attempt: get_authentication_code()}
        )

      conn = submit_form(form, conn)

      assert redirected_to(conn) == ~p"/"
    end
  end

  def get_authentication_code() do
    message =
      FakeSmsService.last_message()
      |> Keyword.fetch!(:body)

    [_, authentication_code] = Regex.run(~r[Your BikeBrigade access code is (\d+)\.], message)

    authentication_code
  end
end
