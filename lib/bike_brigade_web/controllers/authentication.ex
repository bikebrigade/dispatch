defmodule BikeBrigadeWeb.Authentication do
  use BikeBrigadeWeb, :controller

  import Plug.Conn

  alias BikeBrigade.Accounts
  alias BikeBrigade.AuthenticationMessenger

  def login(conn, %{"login" => %{"phone" => phone, "token_attempt" => token_attempt}}) do
    case AuthenticationMessenger.validate_token(phone, token_attempt) do
      :ok ->
        user = Accounts.get_user_by_phone(phone)

        conn
        |> put_flash(:info, "Welcome!")
        |> do_login(user)
        |> redirect(to: signed_in_path(conn))

      {:error, :token_expired} ->
        conn
        |> put_flash(:error, "Access code is expired. Please try again.")
        |> redirect(to: Routes.login_path(conn, :index))

      {:error, :token_invalid} ->
        conn
        |> put_flash(:error, "Access code is invalid. Please try again.")
        |> redirect(to: Routes.login_path(conn, :index, %{"phone" => phone}))
    end
  end

  @doc "Set the session token and live socket for the user"
  def do_login(conn, user) do
    conn
    |> renew_session()
    |> put_session(:user_id, user.id)
    |> put_session(:live_socket_id, "users_socket:#{user.id}")
  end

  def logout(conn, _params) do
    if live_socket_id = get_session(conn, :live_socket_id) do
      BikeBrigadeWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> put_flash(:info, "Goodbye")
    |> redirect(to: Routes.login_path(conn, :index))
  end

  # TODO
  # The functions below are plugs and should be moved
  def get_user_from_session(conn, _opts) do
    if user_id = get_session(conn, :user_id) do
      case Accounts.get_user(user_id) do
        user when not is_nil(user) ->
          assign(conn, :current_user, user)

        nil ->
          conn
          |> renew_session()
          |> put_flash(:error, "Logged in as user that does not exist")
      end
    else
      conn
    end
  end

  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must login to access this page.")
      |> redirect(to: Routes.login_path(conn, :index))
      |> halt()
    end
  end

  def redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  defp signed_in_path(_conn), do: "/"

  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end
end
