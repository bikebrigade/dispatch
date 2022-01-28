defmodule BikeBrigadeWeb.RiderLive.Show do
  use BikeBrigadeWeb, :live_view

  import Ecto.Query, warn: false

  alias BikeBrigade.Delivery
  alias BikeBrigade.Riders
  alias BikeBrigade.Riders.Rider
  alias BikeBrigade.Delivery.Campaign
  alias BikeBrigade.LocalizedDateTime
  alias BikeBrigade.Repo

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page, :riders)}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _url, socket) do
    rider =
      Riders.get_rider!(id)
      |> Repo.preload([:tags, :campaigns, :stats, program_stats: [:program]])

    # I don't have a good datastructure for campaign history and the schedule so lets keep those just html for now

    {:noreply,
     socket
     |> assign(:rider, rider)
     |> assign(:latest_campaign_info, latest_campaign_info(rider.stats))}
  end

  defp latest_campaign_info(stats) do
    stats =
      stats
      |> Repo.preload(latest_campaign: [:program])

    if stats.latest_campaign do
      "#{stats.latest_campaign.program.name} on #{LocalizedDateTime.to_date(stats.latest_campaign.delivery_start)}"
    else
      "Nothing (yet!)"
    end
  end
end
