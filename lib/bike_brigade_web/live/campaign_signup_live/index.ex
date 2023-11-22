defmodule BikeBrigadeWeb.CampaignSignupLive.Index do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.Utils
  alias BikeBrigade.LocalizedDateTime

  alias BikeBrigade.Delivery
  alias BikeBrigade.Delivery.Campaign
  alias BikeBrigade.Messaging.SmsMessage

  import BikeBrigadeWeb.CampaignHelpers

  @impl true
  def mount(_params, _session, socket) do
    current_week =
      LocalizedDateTime.today()
      |> Date.beginning_of_week()

    {:ok,
     socket
     |> assign(:page, :campaigns)
     |> assign(:page_title, "Campaign Signup List")
     |> assign(:current_week, current_week)
     |> assign(:campaigns, fetch_campaigns(current_week))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end


  defp apply_action(socket, :index, params) do
    socket =
      case params do
        %{"current_week" => week} ->
          week = Date.from_iso8601!(week)

          assign(socket,
            current_week: week,
            campaigns: fetch_campaigns(week)
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

  defp campaign_full_class?(campaign) do
    if campaign.stats.signed_up_rider_count == campaign.stats.task_count do
      "text-green-500"
      else
      "text-red-400"
    end

  end
end
