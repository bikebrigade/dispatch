defmodule BikeBrigadeWeb.CommunityFridgeLive.Index do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.Locations
  alias BikeBrigade.Locations.CommunityFridge

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page, :community_fridges)
     |> assign(:community_fridges, list_community_fridges())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Community Fridge")
    |> assign(:community_fridge, Locations.get_community_fridge!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Community Fridge")
    |> assign(:community_fridge, %CommunityFridge{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Community Fridges")
    |> assign(:community_fridge, nil)
  end

  defp list_community_fridges do
    Locations.list_community_fridges()
  end
end
