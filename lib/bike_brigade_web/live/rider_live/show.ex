defmodule BikeBrigadeWeb.RiderLive.Show do
  use BikeBrigadeWeb, :live_view

  import Ecto.Query, warn: false

  alias BikeBrigade.Riders
  alias BikeBrigade.Riders.Rider
  alias BikeBrigade.Delivery.Campaign
  alias BikeBrigade.LocalizedDateTime
  alias BikeBrigade.Repo

  @impl true
  def mount(_params, session, socket) do
    {:ok,
     socket
     |> assign(:page, :riders)}
  end

  def handle_params(%{"id" => id} = params, _url, socket) do
    rider = Riders.get_rider!(id) |> Repo.preload(:tags)

    raw_stats = stats_for(rider)
    stats = %{
      campaigns: campaigns(raw_stats),
      deliveries: deliveries(raw_stats),
      distance: distance(raw_stats),
      latest_campaign_info: latest_campaign_info(raw_stats)
    }

    # I don't have a good datastructure for campaign history and the schedule so lets keep those just html for now

    {:noreply,
     socket
     |> assign(:rider, rider)
     |> assign(:stats, stats)}
  end

  defp stats_for(rider) do
    query = from r in Rider,
      where: r.id == ^rider.id,
      join: t in assoc(r, :assigned_tasks),
      join: c in assoc(t, :campaign),
      select: %{rider_id: r.id, campaign_id: c.id, task_id: t.id, distance: t.delivery_distance}

    Repo.all(query)
  end

  defp campaigns(rider_stats) do
    rider_stats |> Enum.map(& &1.campaign_id) |> Enum.uniq() |> Enum.count
  end

  defp deliveries(rider_stats) do
    rider_stats |> Enum.map(& &1.task_id) |> Enum.uniq() |> Enum.count
  end

  defp distance(rider_stats) do
    rider_stats |> Enum.map(& &1.distance) |> Enum.sum()
  end

  defp latest_campaign_info(rider_stats) do
    latest_campaign_id = rider_stats |> Enum.map(& &1.campaign_id) |> Enum.max(fn -> nil end)

    if latest_campaign_id do
      latest_campaign = Repo.get(Campaign, latest_campaign_id) |> Repo.preload(:program)

      "#{latest_campaign.program.name} on #{LocalizedDateTime.to_date(latest_campaign.delivery_start)}"
    else
      "Nothing (yet!)"
    end
  end
end
