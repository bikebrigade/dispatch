defmodule BikeBrigadeWeb.RiderLive.MapComponent do
  use BikeBrigadeWeb, :live_component

  alias BikeBrigadeWeb.RiderLive.RiderMarkerComponent

  @impl true
  def render(assigns) do
    ~H"""
    <leaflet-map phx-update="append" phx-hook= "LeafletMap" id="task-map" data-lat={@lat} data-lng={@lng}
        data-mapbox_access_token="pk.eyJ1IjoibXZleXRzbWFuIiwiYSI6ImNrYWN0eHV5eTBhMTMycXI4bnF1czl2ejgifQ.xGiR6ANmMCZCcfZ0x_Mn4g"
        class="h-full">
      <%= for rider <- @riders do %>
        <.live_component id={rider.id} module={RiderMarkerComponent} rider={rider} selected={@selected_rider && @selected_rider.id == rider.id} />
      <% end %>
    </leaflet-map>
    """
  end
end
