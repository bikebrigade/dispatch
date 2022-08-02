defmodule BikeBrigadeWeb.ItineraryLive.Index do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.LocalizedDateTime
  alias BikeBrigade.Riders
  alias BikeBrigade.Delivery

  import BikeBrigadeWeb.CampaignHelpers

  @impl true
  def mount(_params, _session, socket) do
    today = LocalizedDateTime.today()

    {:ok,
     socket
     |> assign(:page, :itinerary)
     |> assign(:page_title, "Itinerary")
     |> assign(:today, today)
     |> assign(:deliveries, fetch_deliveries(socket, today))}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  defp fetch_deliveries(socket, today) do
    Riders.list_campaigns_with_task_counts(
      Riders.get_rider!(
        if not is_nil(socket.assigns.current_user.rider_id),
          do: socket.assigns.current_user.rider_id,
          else: 26
      ),
      today
    )
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
          <%= Delivery.get_campaign(assigns.delivery.id).location.address %>
        </p>
      </div>
    </div>
    """
  end
end
