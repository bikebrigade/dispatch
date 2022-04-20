defmodule BikeBrigadeWeb.CampaignLive.RiderMarkerComponent do
  use BikeBrigadeWeb, :live_component
  import BikeBrigadeWeb.CampaignHelpers
  @impl true
  def render(assigns) do
    ~H"""
    <leaflet-marker
      phx-hook="LeafletMarker"
      id={"rider-marker:#{@rider.id}"}
      data-lat={lat(@rider.location)}
      data-lng={lng(@rider.location)}
      data-icon="bicycle"
      data-color={
        cond do
          selected?(@selected_rider, @rider) -> "#5850ec"
          task_rider?(@selected_task, @rider) -> "#0e9f6e"
          @rider.assigned_tasks != [] -> "#4a5568"
          true -> "#a0aec0"
        end
      }
      data-click-event="select-rider"
      data-click-value-id={@rider.id}
    >
      <%= if  selected?(@selected_rider, @rider) do %>
        <leaflet-circle
          phx-hook="LeafletCircle"
          id={"rider-circle:#{@rider.id}"}
          data-lat={lat(@rider.location)}
          data-lng={lng(@rider.location)}
          data-radius={@rider.max_distance * 250}
        >
        </leaflet-circle>
      <% end %>
    </leaflet-marker>
    """
  end
end
