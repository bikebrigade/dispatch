defmodule BikeBrigadeWeb.LiveHooks.Authentication do
  import Phoenix.LiveView

  alias BikeBrigade.Accounts

  def on_mount(:default, _params, %{"user_id" => user_id}, socket) do
    if user = Accounts.get_user(user_id) do
      # Set the context for Honeybadger here
      Honeybadger.context(context: %{user_id: user.id, user_email: user.email})

      {:cont,
       socket
       |> Phoenix.Component.assign_new(:current_user, fn -> user end)
       |> Phoenix.Component.assign_new(:page_title, fn -> nil end)}
    else
      {:halt,
       socket
       |> push_redirect(to: "/login")}
    end
  end

  def on_mount(:default, _params, %{}, socket) do
    {:halt,
     socket
     |> push_redirect(to: "/login")}
  end

  def on_mount(:require_dispatcher, _params, %{"user_id" => user_id}, socket) do
    case Accounts.get_user(user_id) do
      %{is_dispatcher: true} = user ->
        # Set the context for Honeybadger here
        Honeybadger.context(context: %{user_id: user.id, user_email: user.email})

        {:cont,
         socket
         |> Phoenix.Component.assign_new(:current_user, fn -> user end)
         |> Phoenix.Component.assign_new(:page_title, fn -> nil end)}

      _ ->
        {:halt,
         socket
         |> put_flash(:error, "Must be a dispatcher to access this page")
         |> push_redirect(to: "/login")}
    end
  end
end
