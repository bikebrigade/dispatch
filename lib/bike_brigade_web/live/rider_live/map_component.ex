defmodule BikeBrigadeWeb.RiderLive.MapComponent do
  use BikeBrigadeWeb, :live_component

  alias BikeBrigadeWeb.RiderLive.RiderMarkerComponent

  @impl true
  def render(assigns) do
    ~H"""
    <leaflet-map phx-update="append" phx-hook= "LeafletMap" id="task-map" data-lat={@lat} data-lng={@lng}
        data-mapbox_access_token="pk.eyJ1IjoibXZleXRzbWFuIiwiYSI6ImNrYWN0eHV5eTBhMTMycXI4bnF1czl2ejgifQ.xGiR6ANmMCZCcfZ0x_Mn4g"
        class="h-full">
      <%= if @located_place do %>
        <leaflet-marker phx-hook="LeafletMarker" id="located_place" data-lat={@located_place.lat} data-lng={@located_place.lon}
          data-icon="circle" data-color="#1c64f2" data-zindex="100"></leaflet-marker>
      <% end %>
      <%= for rider <- @riders do %>
        <.live_component module={RiderMarkerComponent} rider={rider} selected={@selected_rider && @selected_rider.id == rider.id} />
      <% end %>
    </leaflet-map>
    """
  end
end
