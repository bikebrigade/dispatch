defmodule BikeBrigadeWeb.CommunityFridgeLive.Index do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.Locations
  alias BikeBrigade.Locations.CommunityFridge

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page, :community_fridges)
     |> assign(:page_title, "Community Fridges")
     |> assign(:community_fridge, nil)
     |> assign(:community_fridges, Locations.list_community_fridges())}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Community Fridges")
    |> assign(:community_fridge, nil)
    |> assign(:community_fridges, Locations.list_community_fridges())
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Fridge")
    |> assign(:community_fridge, %CommunityFridge{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Fridge")
    |> assign(:community_fridge, Locations.get_community_fridge!(id))
  end
end
