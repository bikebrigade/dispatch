defmodule BikeBrigadeWeb.RiderHomeLive.Index do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.LocalizedDateTime
  alias BikeBrigade.Riders

  import BikeBrigadeWeb.CampaignHelpers

  alias BikeBrigade.Utils

  @impl true
  def mount(_params, _session, socket) do
    today = LocalizedDateTime.today()

    {:ok,
     socket
     |> assign(:page, :home)
     |> assign(:page_title, "Home")
     |> load_itinerary(today)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    # {:noreply, apply_action(socket, socket.assigns.live_action, params)}
    {:noreply, socket}
  end

  # defp apply_action(socket, :index, params) do
  #   date =
  #     case params do
  #       %{"date" => date} -> Date.from_iso8601!(date)
  #       _ -> LocalizedDateTime.today()
  #     end

  #   load_itinerary(socket, date)
  # end

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

  defp get_task_count(campaign_riders) do
    campaign_riders
    |> Enum.map(fn cr -> length(cr.campaign.tasks) end)
    |> Enum.sum()
  end

  # Note Utils has a `humanized_task_count/1` which is similar but breaks
  # things down by delivery type
  defp delivery_count(tasks) do
    task_count = Utils.task_count(tasks)
    "#{task_count} #{Inflex.inflect("delivery", task_count)}"
  end
end
