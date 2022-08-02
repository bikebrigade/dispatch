defmodule BikeBrigadeWeb.ItineraryLive.Index do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.LocalizedDateTime
  alias BikeBrigade.Riders

  import BikeBrigadeWeb.CampaignHelpers

  @impl true
  def mount(_params, _session, socket) do
    # TODO: browse itinerary by date
    date = LocalizedDateTime.today()

    # In the future we may have current_user.rider preloaded, but for now we will load it in `fetch_campaigns/2`
    rider_id = socket.assigns.current_user.rider_id

    socket =
      if rider_id do
        socket
        |> assign(
          :campaigns,
          fetch_campaigns(rider_id, date)
        )
      else
        socket
        |> assign(:campaigns, [])
        |> put_flash(:error, "User is not associated with a rider!")
      end

    {:ok,
     socket
     |> assign(:page, :itinerary)
     |> assign(:page_title, "Itinerary")
     |> assign(:date, date)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  defp fetch_campaigns(rider_id, date) do
    Riders.get_rider!(rider_id)
    |> Riders.list_campaigns_with_task_counts(date)
  end

  defp get_location(assigns) do
    ~H"""
    <div class="mt-2 sm:flex sm:justify-between">
      <div class="sm:flex">
        <p class="flex items-center text-sm text-gray-500">
          <Heroicons.Outline.location_marker
            aria-label="Location"
            class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400"
          />
          <%= @campaign.location.address %>
        </p>
      </div>
    </div>
    """
  end

  defp get_task_count(campaigns) do
    Enum.reduce(campaigns, 0, fn {_campaign, task_count}, acc -> task_count + acc end)
  end
end
