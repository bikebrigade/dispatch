defmodule BikeBrigadeWeb.ItineraryLive.Index do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.LocalizedDateTime
  alias BikeBrigade.Riders

  import BikeBrigadeWeb.CampaignHelpers

  import BikeBrigade.Utils, only: [humanized_task_count: 1]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page, :itinerary)
     |> assign(:page_title, "Itinerary")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, params) do
    date =
      case params do
        %{"date" => date} -> Date.from_iso8601!(date)
        _ -> LocalizedDateTime.today()
      end

    load_itinerary(socket, date)
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
    <div class="mt-2 sm:flex sm:justify-between">
      <div class="sm:flex">
        <p class="flex items-center text-sm text-gray-500">
          <Heroicons.map_pin aria-label="Location" class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" />
          <%= @campaign.location.address %>
        </p>
      </div>
    </div>
    """
  end

  defp get_task_count(campaign_riders) do
    campaign_riders
    |> Enum.map(fn cr -> length(cr.campaign.tasks) end)
    |> Enum.sum()
  end
end
