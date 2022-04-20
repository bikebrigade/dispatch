defmodule BikeBrigadeWeb.LiveHooks.Authentication do
  import Phoenix.LiveView

  alias BikeBrigade.Accounts

  def on_mount(:default, _params, %{"user_id" => user_id}, socket) do
    # can this ever return nil?
    user = Accounts.get_user(user_id)

    # Set the context for Honeybadger here
    Honeybadger.context(context: %{user_id: user.id, user_email: user.email})

    {:cont,
     socket
     |> assign_new(:current_user, fn -> user end)
     |> assign_new(:page_title, fn -> nil end)}
  end

  def on_mount(:default, _params, %{}, socket) do
    {:halt,
     socket
     |> push_redirect(to: "/login")}
  end
end
