defmodule BikeBrigadeWeb.CampaignLive.MapComponent do
  use BikeBrigadeWeb, :live_component

  import BikeBrigadeWeb.CampaignHelpers

  alias BikeBrigadeWeb.CampaignLive.RiderMarkerComponent

  @impl true
  def update(assigns, socket) do
    %{tasks: tasks, riders: riders, tasks_query: tasks_query, riders_query: riders_query} =
      assigns

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:tasks_list, filter_tasks(tasks, tasks_query))
     |> assign(:riders_list, filter_riders(riders, riders_query))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <leaflet-map
      phx-hook="LeafletMap"
      id="task-map"
      data-lat={lat(@campaign.location)}
      data-lng={lng(@campaign.location)}
      data-mapbox_access_token="pk.eyJ1IjoibXZleXRzbWFuIiwiYSI6ImNrYWN0eHV5eTBhMTMycXI4bnF1czl2ejgifQ.xGiR6ANmMCZCcfZ0x_Mn4g"
      class="h-full"
    >
      <leaflet-marker
        phx-hook="LeafletMarker"
        id={"task-from-marker:#{@campaign.id}"}
        data-lat={lat(@campaign.location)}
        data-lng={lng(@campaign.location)}
        data-icon="warehouse"
        data-color="#1c64f2"
      >
      </leaflet-marker>
      <%= for {_id, task} <- @tasks_list do %>
        <leaflet-marker
          phx-hook="LeafletMarker"
          id={"task-to-marker:#{task.id}"}
          data-click-event="select-task"
          data-click-value-id={task.id}
          data-lat={lat(task.dropoff_location)}
          data-lng={lng(task.dropoff_location)}
          data-icon={if task_assigned?(task), do: "circle", else: "cross"}
          data-color={
            cond do
              selected?(@selected_task, task) -> "#5145cd"
              rider_task?(@selected_rider, task) -> "#6875f5"
              true -> "#c3ddfd"
            end
          }
        >
        </leaflet-marker>
      <% end %>
      <%= for {_id, rider} <- @riders_list do %>
        <.live_component
          module={RiderMarkerComponent}
          id={rider.id}
          rider={rider}
          selected_rider={@selected_rider}
          selected_task={@selected_task}
        />
      <% end %>
    </leaflet-map>
    """
  end
end
