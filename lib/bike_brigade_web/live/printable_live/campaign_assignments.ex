defmodule BikeBrigadeWeb.PrintableLive.CampaignAssignments do
  use BikeBrigadeWeb, {:live_view, layout: {BikeBrigadeWeb.LayoutView, "fullscreen.live.html"}}
  import BikeBrigadeWeb.CampaignHelpers

  alias BikeBrigade.Delivery

  import BikeBrigadeWeb.PrintableLive.Helpers

  @impl true
  def mount(_params, session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    campaign = Delivery.get_campaign(id)

    tasks =
      campaign.tasks
      |> Enum.sort_by(&(&1.assigned_rider && String.downcase(&1.assigned_rider.name)))

    {:noreply,
     socket
     |> assign(:campaign_title, name(campaign))
     |> assign(:campaign_date, campaign.delivery_date)
     |> assign(:tasks, tasks)}
  end
end
