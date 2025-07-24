defmodule BikeBrigadeWeb.UserLive.Index do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.Accounts
  alias BikeBrigade.Accounts.User

  @impl true
  def mount(_params, _session, socket) do
    if socket.assigns.current_user.is_dispatcher do
      {:ok,
       socket
       |> assign(:page, :users)
       |> assign(:users, list_users())}
    else
      {:ok,
       socket
       |> put_flash(:error, "You must be a dispatcher to view this page")
       # TODO redirect where?
       |> push_navigate(to: "/riders")}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit User")
    |> assign(:user, Accounts.get_user(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New User")
    |> assign(:user, %User{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Users")
    |> assign(:user, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = Accounts.get_user(id)
    {:ok, _} = Accounts.delete_user(user)

    {:noreply, assign(socket, :users, list_users())}
  end

  defp list_users do
    Accounts.list_users()
  end
end
