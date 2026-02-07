defmodule BikeBrigadeWeb.UserLive.Index do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.Accounts
  alias BikeBrigade.Accounts.User

  @per_page 20

  @impl true
  def mount(_params, _session, socket) do
    if socket.assigns.current_user.is_dispatcher do
      {:ok,
       socket
       |> assign(:page, :users)
       |> assign(:search, "")
       |> assign(:dispatchers_only, true)
       |> assign(:current_page, 1)
       |> assign(:total, 0)
       |> assign(:page_first, 0)
       |> assign(:page_last, 0)
       |> assign(:users, [])}
    else
      {:ok,
       socket
       |> put_flash(:error, "You must be a dispatcher to view this page")
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

  defp apply_action(socket, :index, params) do
    search = Map.get(params, "search", "")
    dispatchers_only = Map.get(params, "dispatchers_only", "true") == "true"
    page = params |> Map.get("page", "1") |> String.to_integer() |> max(1)

    {users, total} =
      Accounts.list_users_paginated(%{
        search: search,
        dispatchers_only: dispatchers_only,
        page: page
      })

    page_first = if total == 0, do: 0, else: (page - 1) * @per_page + 1
    page_last = min(page * @per_page, total)

    socket
    |> assign(:page_title, "Listing Users")
    |> assign(:user, nil)
    |> assign(:users, users)
    |> assign(:search, search)
    |> assign(:dispatchers_only, dispatchers_only)
    |> assign(:current_page, page)
    |> assign(:total, total)
    |> assign(:page_first, page_first)
    |> assign(:page_last, page_last)
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    {:noreply, push_patch(socket, to: patch_path(socket, search: search, page: 1))}
  end

  def handle_event("clear_search", _params, socket) do
    {:noreply, push_patch(socket, to: patch_path(socket, search: "", page: 1))}
  end

  def handle_event("toggle_dispatchers", _params, socket) do
    {:noreply,
     push_patch(socket,
       to: patch_path(socket, dispatchers_only: !socket.assigns.dispatchers_only, page: 1)
     )}
  end

  def handle_event("next_page", _params, socket) do
    {:noreply, push_patch(socket, to: patch_path(socket, page: socket.assigns.current_page + 1))}
  end

  def handle_event("prev_page", _params, socket) do
    {:noreply,
     push_patch(socket, to: patch_path(socket, page: max(socket.assigns.current_page - 1, 1)))}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    user = Accounts.get_user(id)
    {:ok, _} = Accounts.delete_user(user)

    {:noreply, fetch_users(socket)}
  end

  defp fetch_users(socket) do
    page = socket.assigns.current_page

    {users, total} =
      Accounts.list_users_paginated(%{
        search: socket.assigns.search,
        dispatchers_only: socket.assigns.dispatchers_only,
        page: page
      })

    page_first = if total == 0, do: 0, else: (page - 1) * @per_page + 1
    page_last = min(page * @per_page, total)

    socket
    |> assign(:users, users)
    |> assign(:total, total)
    |> assign(:page_first, page_first)
    |> assign(:page_last, page_last)
  end

  defp patch_path(socket, overrides) do
    search = Keyword.get(overrides, :search, socket.assigns.search)
    dispatchers_only = Keyword.get(overrides, :dispatchers_only, socket.assigns.dispatchers_only)
    page = Keyword.get(overrides, :page, socket.assigns.current_page)

    params =
      %{}
      |> then(fn p -> if search != "", do: Map.put(p, "search", search), else: p end)
      |> then(fn p ->
        if !dispatchers_only, do: Map.put(p, "dispatchers_only", "false"), else: p
      end)
      |> then(fn p -> if page > 1, do: Map.put(p, "page", page), else: p end)

    ~p"/users?#{params}"
  end
end
