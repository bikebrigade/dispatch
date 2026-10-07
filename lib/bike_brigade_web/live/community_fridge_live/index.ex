defmodule BikeBrigadeWeb.CommunityFridgeLive.Index do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.Locations
  alias BikeBrigade.Locations.CommunityFridge

  # Toronto city hall as fallback centre
  @default_coords %Geo.Point{coordinates: {-79.3832, 43.6532}}

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page, :community_fridges)
     |> assign(:page_title, "Community Fridges")
     |> assign(:community_fridge, nil)
     |> assign(:community_fridges, Locations.list_community_fridges())
     |> assign(:map_layers, [])
     |> assign(:map_coords, @default_coords)
     |> assign(:mode, :list)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl Phoenix.LiveView
  def handle_event("set_mode", %{"mode" => mode}, socket) do
    socket = assign(socket, :mode, String.to_existing_atom(mode))

    socket =
      if socket.assigns.mode == :map do
        push_event(socket, "leaflet:redraw_map", %{recenter: false})
      else
        socket
      end

    {:noreply, socket}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Community Fridges")
    |> assign(:community_fridge, nil)
    |> assign(:map_layers, fridge_markers(socket.assigns.community_fridges))
    |> assign(:map_coords, map_center(socket.assigns.community_fridges))
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

  defp fridge_markers(community_fridges) do
    for %{id: id, name: name, location: location} <- community_fridges,
        not is_nil(location),
        not is_nil(location.coords) do
      %{
        id: "fridge-#{id}",
        type: :marker,
        data: %{
          lat: lat(location),
          lng: lng(location),
          icon: "warehouse",
          color: "#1c64f2",
          tooltip: name
        }
      }
    end
  end

  defp map_center(community_fridges) do
    community_fridges
    |> Enum.find_value(fn %{location: location} ->
      location && location.coords
    end)
    |> case do
      nil -> @default_coords
      coords -> coords
    end
  end
end
