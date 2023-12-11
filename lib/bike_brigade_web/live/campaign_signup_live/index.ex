defmodule BikeBrigadeWeb.CampaignSignupLive.Index do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.Utils
  alias BikeBrigade.LocalizedDateTime
  alias BikeBrigade.Delivery

  import BikeBrigadeWeb.CampaignHelpers

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Delivery.subscribe()
    end

    current_week =
      LocalizedDateTime.today()
      |> Date.beginning_of_week()

    campaigns = fetch_campaigns(current_week)

    {:ok,
     socket
     |> assign(:page, :campaigns)
     |> assign(:page_title, "Campaign Signup List")
     |> assign(:current_week, current_week)
     # REVIEW: rename this to `campaign_meta` ?
     |> assign(:campaign_task_counts, Delivery.get_total_tasks_and_open_tasks(current_week))
     |> assign(:campaigns, campaigns)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  # -- Delivery callbacks

  @broadcasted_infos [
    :task_created,
    :task_deleted,
    :task_updated,
    :campaign_rider_created,
    :campaign_rider_deleted
  ]

  @impl Phoenix.LiveView
  def handle_info({event, entity}, socket) when event in @broadcasted_infos do
    if entity_in_campaigns?(socket, entity.campaign_id) do
      {:noreply, refetch_and_assign_data(socket)}
    else
      {:noreply, socket}
    end
  end

  ## -- End Delivery callbacks

  defp apply_action(socket, :index, params) do
    socket =
      case params do
        %{"current_week" => week} ->
          week = Date.from_iso8601!(week)

          assign(socket,
            current_week: week,
            campaigns: fetch_campaigns(week),
            campaign_task_counts: Delivery.get_total_tasks_and_open_tasks(week)
          )

        _ ->
          socket
      end

    socket
    |> assign(:campaign, nil)
  end

  defp fetch_campaigns(current_week) do
    Delivery.list_campaigns(current_week,
      preload: [:program, :stats, :latest_message, :scheduled_message]
    )
    |> Enum.reverse()
    |> Utils.ordered_group_by(&LocalizedDateTime.to_date(&1.delivery_start))
    |> Enum.reverse()
  end

  defp refetch_and_assign_data(socket) do
    week = socket.assigns.current_week

    socket
    |> assign(:campaign_task_counts, Delivery.get_total_tasks_and_open_tasks(week))
    |> assign(:campaigns, fetch_campaigns(week))
  end

  defp campaign_is_in_past(campaign) do
    date_now = DateTime.utc_now()

    case DateTime.compare(campaign.delivery_end, date_now) do
      :gt -> false
      :eq -> false
      :lt -> true
    end
  end

  defp get_signup_text(campaign_id, rider_id, campaign_task_counts) do
    count_tasks_for_current_rider =
      campaign_task_counts[campaign_id].rider_ids
      |> Enum.count(fn i -> i == Integer.to_string(rider_id) end)

    cond do
      count_tasks_for_current_rider > 0 ->
        "Signed up for #{count_tasks_for_current_rider} deliveries"

      true ->
        "Sign up"
    end
  end

  defp campaign_tasks_fully_assigned?(c_id, campaign_task_count) do
    campaign_task_count[c_id][:filled_tasks] == campaign_task_count[c_id][:total_tasks]
  end

  # Use this to determine if we need to refetch data to update the liveview.
  # ex: dispatcher changes riders/tasks, or another rider signs up -> refetch.
  defp entity_in_campaigns?(socket, entity_campaign_id) do
    socket.assigns.campaigns
    |> Enum.flat_map(fn {_date, campaigns} -> campaigns end)
    |> Enum.find(false, fn c -> c.id == entity_campaign_id end)
  end
end
