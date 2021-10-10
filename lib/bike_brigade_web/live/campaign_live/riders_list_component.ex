defmodule BikeBrigadeWeb.CampaignLive.RidersListComponent do
  use BikeBrigadeWeb, :live_component
  require Logger

  import BikeBrigadeWeb.CampaignHelpers
  import BikeBrigade.Utils, only: [task_count: 1]

  def update(assigns, socket) do
    %{campaign: campaign, riders_query: riders_query} = assigns

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:riders_list, filter_riders(campaign.riders, riders_query))}
  end
end
