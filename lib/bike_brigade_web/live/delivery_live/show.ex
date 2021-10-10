defmodule BikeBrigadeWeb.DeliveryLive.Show do
  use BikeBrigadeWeb, {:live_view, layout: {BikeBrigadeWeb.LayoutView, "public.live.html"}}

  alias BikeBrigade.LocalizedDateTime
  alias BikeBrigade.Delivery
  alias BikeBrigadeWeb.CampaignHelpers
  import BikeBrigadeWeb.DeliveryHelpers
  import BikeBrigade.Utils, only: [humanized_task_count: 1]

  alias BikeBrigadeWeb.DeliveryExpiredError

  @check_expiry Mix.env() == :prod

  @impl Phoenix.LiveView
  def mount(%{"token" => token}, _session, socket) do
    %{campaign: campaign, rider: rider, pickup_window: pickup_window} = Delivery.get_campaign_rider!(token)
    # TODO this is hacky but will go away

    rider = %{rider | pickup_window: pickup_window}

    # TODO delivery date will be gone
    campaign_date = if campaign.delivery_start do
      LocalizedDateTime.to_date(campaign.delivery_start)
    else
      campaign.delivery_date

    end

    if @check_expiry && Date.diff(Date.utc_today(), campaign_date) > 5 do
      raise DeliveryExpiredError
    end

    multiple_unique_tasks = Enum.count(rider.assigned_tasks, & &1.request_type) > 1

    {:ok,
     socket
     |> assign(:campaign, campaign)
     |> assign(:campaign_date, campaign_date)
     |> assign(:page_title, "#{campaign_name(campaign)} - #{campaign_date}")
     |> assign(:rider, rider)
     |> assign(:multiple_unique_tasks, multiple_unique_tasks)}
  end
end
