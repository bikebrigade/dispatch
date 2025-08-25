defmodule BikeBrigadeWeb.RiderHomeLive.Index do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.{Delivery, Notifications, Riders, Stats, LocalizedDateTime}

  import BikeBrigadeWeb.CampaignHelpers

  alias BikeBrigade.Utils

  @impl true
  def mount(_params, _session, socket) do
    today = LocalizedDateTime.today()
    rider_id = socket.assigns.current_user.rider_id

    # Subscribe to banner updates
    Notifications.subscribe()

    {:ok,
     socket
     |> assign(:page, :home)
     |> assign(:page_title, "Home")
     |> assign(:stats, Stats.home_stats())
     |> assign(:rider, Riders.get_rider!(rider_id))
     |> assign(:urgent_campaigns, Delivery.list_urgent_campaigns())
     |> assign(:active_banners, get_active_banners())
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
        {@campaign.location.address}
      </p>
    </div>
    """
  end

  defp get_pickup_window(assigns) do
    ~H"""
    <div class="sm:flex sm:justify-between">
      <p class="flex items-center">
        <Heroicons.clock aria-label="Pickup Time" class="flex-shrink-0 w-4 h-4 mr-1 text-gray-400" />
        {pickup_window(@campaign)}
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

  defp has_urgent_campaigns?(urgent_campaigns) do
    Enum.count(urgent_campaigns) > 0
  end

  @impl true
  def handle_info({:banner_created, _banner}, socket) do
    {:noreply, assign(socket, :active_banners, get_active_banners())}
  end

  def handle_info({:banner_updated, _banner}, socket) do
    {:noreply, assign(socket, :active_banners, get_active_banners())}
  end

  def handle_info({:banner_deleted, _banner}, socket) do
    {:noreply, assign(socket, :active_banners, get_active_banners())}
  end

  defp get_active_banners() do
    # currently broken, due to a missed-migration.
    []
    # do note use below, replace when db is fixed:
    # Notifications.list_active_banners()
  end

  defp num_unassigned_tasks_and_campaigns(urgent_campaigns) do
    # formats a string so that we see: "program 1, program 2, and program 3" (ie, we want that 'and') in there.
    campaign_ids = urgent_campaigns |> Enum.map(& &1.id)

    campaign_names =
      urgent_campaigns
      |> Enum.map(& &1.program.name)
      |> Enum.uniq()
      |> Utils.join()

    deliveries_without_riders =
      urgent_campaigns
      |> Enum.flat_map(& &1.tasks)
      |> Enum.count(fn task -> task.assigned_rider_id == nil end)

    {deliveries_without_riders, campaign_names, campaign_ids}
  end
end
