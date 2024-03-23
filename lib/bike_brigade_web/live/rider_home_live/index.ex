defmodule BikeBrigadeWeb.RiderHomeLive.Index do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.LocalizedDateTime
  alias BikeBrigade.Riders
  alias BikeBrigade.Stats

  import BikeBrigadeWeb.CampaignHelpers
  import BikeBrigade.Riders.Helpers, only: [first_name: 1]

  alias BikeBrigade.Utils

  @impl true
  def mount(_params, _session, socket) do
    today = LocalizedDateTime.today()
    rider_id = socket.assigns.current_user.rider_id

    {:ok,
     socket
     |> assign(:page, :home)
     |> assign(:page_title, "Home")
     |> assign(:stats, Stats.home_stats())
     |> assign(:rider, Riders.get_rider!(rider_id))
     |> load_itinerary(today)}
  end

  defp load_itinerary(socket, date) do
    rider_id = socket.assigns.current_user.rider_id

    if rider_id do
      socket
      |> assign(
        :campaign_riders,
        Riders.get_itinerary(rider_id, date)
      )
    else
      socket
      |> assign(:campaign_riders, [])
      |> put_flash(:error, "User is not associated with a rider!")
    end
    |> assign(:date, date)
  end

  defp get_location(assigns) do
    ~H"""
    <div class="sm:flex sm:justify-between">
      <p class="flex items-center">
        <Heroicons.map_pin aria-label="Location" class="flex-shrink-0 w-4 h-4 mr-1 text-gray-400" />
        <%= @campaign.location.address %>
      </p>
    </div>
    """
  end

  defp get_pickup_window(assigns) do
    ~H"""
    <div class="sm:flex sm:justify-between">
      <p class="flex items-center">
        <Heroicons.clock aria-label="Pickup Time" class="flex-shrink-0 w-4 h-4 mr-1 text-gray-400" />
        <%= pickup_window(@campaign) %>
      </p>
    </div>
    """
  end

  # Note Utils has a `humanized_task_count/1` which is similar but breaks
  # things down by delivery type
  defp delivery_count(tasks) do
    task_count = Utils.task_count(tasks)
    "#{task_count} #{Inflex.inflect("delivery", task_count)}"
  end
end
