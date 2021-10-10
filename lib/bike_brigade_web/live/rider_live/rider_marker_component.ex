defmodule BikeBrigadeWeb.RiderLive.RiderMarkerComponent do
  use BikeBrigadeWeb, :live_component
  require Logger

  @impl true
  def mount(socket) do
    {:ok, assign(socket, selected: false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <leaflet-marker phx-hook="LeafletMarker" id={"rider-marker:#{@rider.id}"} data-lat={lat(@rider.location)} data-lng={lng(@rider.location)}
        data-icon="bicycle"
        data-color={if @selected, do: "#5850ec", else: "#4a5568"}
        data-click-event="select-rider" data-click-value-id={@rider.id}>
        <%= if @selected do %>
        <leaflet-circle phx-hook="LeafletCircle" id={"rider-circle:#{@rider.id}"} data-lat={lat(@rider.location)} data-lng={lng(@rider.location)}
          data-radius={@rider.max_distance * 250}></leaflet-circle>
          <% end %>
      </leaflet-marker>
    """
  end
end
