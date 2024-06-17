defmodule BikeBrigadeWeb.AuthenticationController do
  use BikeBrigadeWeb, :controller

  import Plug.Conn

  alias BikeBrigade.Accounts
  alias BikeBrigade.AuthenticationMessenger

  defmodule Login do
    use BikeBrigade.Schema
    import Ecto.Changeset

    alias BikeBrigade.EctoPhoneNumber

    @primary_key false
    embedded_schema do
      field :phone, EctoPhoneNumber.Canadian
      field :token_attempt, :string
    end

    def validate_phone(attrs) do
      %Login{}
      |> cast(attrs, [:phone])
      |> validate_required([:phone])
      |> validate_user_exists(:phone)
      |> Ecto.Changeset.apply_action(:insert)
    end

    defp validate_user_exists(changeset, field) when is_atom(field) do
      validate_change(changeset, field, fn _, phone ->
        case Accounts.get_user_by_phone(phone) do
          nil -> [{field, "We can't find your number. Have you signed up for Bike Brigade?"}]
          _ -> []
        end
      end)
    end
  end

  def show(conn, %{"login" => %{"phone" => phone}}) do
    changeset = Ecto.Changeset.change(%Login{phone: phone})
    # TODO: validate phone number
    # TODO: send token

    conn
    |> render("show.html", state: :token, changeset: changeset, layout: false)
  end

  def show(conn, _params) do
    changeset = Ecto.Changeset.change(%Login{})

    conn
    |> render("show.html", state: :phone, changeset: changeset, layout: false)
  end

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
        |> redirect(to: ~p"/login")

      {:error, :token_invalid} ->
        conn
        |> put_flash(:error, "Access code is invalid. Please try again.")
        |> redirect(to: ~p"/login?#{%{phone: phone}}")
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
    |> redirect(to: ~p"/login")
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
      |> redirect(to: ~p"/login")
      |> halt()
    end
  end

  def require_dispatcher(conn, _opts) do
    case conn.assigns[:current_user] do
      %{is_dispatcher: true} ->
        conn

      _ ->
        conn
        |> put_flash(:error, "You must be a dispatcher to access this page.")
        |> redirect(to: ~p"/login")
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
