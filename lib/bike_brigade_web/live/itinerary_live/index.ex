defmodule BikeBrigadeWeb.ItineraryLive.Index do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.LocalizedDateTime
  alias BikeBrigade.Riders

  import BikeBrigadeWeb.CampaignHelpers

  @impl true
  def mount(_params, _session, socket) do
    today = LocalizedDateTime.today()

    {:ok,
     socket
     |> assign(:page, :itinerary)
     |> assign(:page_title, "Itinerary")
     |> assign(:today, today)
     |> assign(:campaigns, fetch_campaigns(socket, today))}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  defp fetch_campaigns(socket, today) do
    if not is_nil(socket.assigns.current_user.rider_id) do
      Riders.list_campaigns_with_task_counts(
        Riders.get_rider!(socket.assigns.current_user.rider_id),
        today
      )
    else
      socket |> put_flash(:error, "User needs rider_id")

      Riders.list_campaigns_with_task_counts(
        Riders.get_rider!(26),
        ~D[2022-06-27]
      )
    end
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
