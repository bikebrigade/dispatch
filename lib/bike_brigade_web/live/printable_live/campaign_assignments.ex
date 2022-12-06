defmodule BikeBrigadeWeb.PrintableLive.CampaignAssignments do
  use BikeBrigadeWeb, {:live_view, layout: :fullscreen}
  import BikeBrigadeWeb.CampaignHelpers

  alias BikeBrigade.Delivery

  import BikeBrigadeWeb.PrintableLive.Helpers

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    campaign = Delivery.get_campaign(id)
    {_riders, tasks} = Delivery.campaign_riders_and_tasks(campaign)

    tasks =
      tasks
      |> Enum.sort_by(&(&1.assigned_rider && String.downcase(&1.assigned_rider.name)))

    {:noreply,
     socket
     |> assign(:campaign_title, name(campaign))
     |> assign(:campaign_date, campaign_date(campaign))
     |> assign(:tasks, tasks)}
  end
end
