defmodule BikeBrigadeWeb.CalendarLive.Index do
  alias BikeBrigade.Delivery.{Campaign, Opportunity}
  use BikeBrigadeWeb, {:live_view, layout: :public}

  alias BikeBrigade.Utils
  alias BikeBrigade.Delivery
  alias BikeBrigade.LocalizedDateTime
  alias BikeBrigade.Locations

  alias BikeBrigade.GoogleMaps

  @impl true
  def mount(_params, _session, socket) do
    # if connected?(socket) do
    #  Delivery.subscribe()
    # end

    start_date = today = LocalizedDateTime.today()
    campaigns_and_opportunities = list_campaigns_and_opportunities(start_date)

    end_date =
      case List.last(campaigns_and_opportunities) do
        {end_date, _} -> end_date
        nil -> start_date
      end

    {:ok,
     socket
     |> assign(:show_buttons, false)
     |> assign(:today, today)
     |> assign(:start_date, start_date)
     |> assign(:end_date, end_date)
     |> assign(:campaigns_and_opportunities, campaigns_and_opportunities)}
  end

  @impl true
  def handle_params(%{"show_buttons" => "true"}, _url, socket) do
    {:noreply, assign(socket, :show_buttons, true)}
  end

  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  # defp apply_action(socket, :index, _params) do
  #   socket
  #   |> assign(:expanded, nil)
  # end

  # defp apply_action(socket, :show, %{"id" => id}) do
  #   socket
  #   |> assign(:expanded, String.to_integer(id))
  # end

  def list_campaigns_and_opportunities(start_date) do
    opportunities =
      Delivery.list_opportunities(
        start_date: start_date,
        published: true,
        preload: [location: [:neighborhood], program: [:items]]
      )

    campaigns =
      Delivery.list_campaigns(
        start_date: start_date,
        public: true,
        preload: [location: [:neighborhood], program: [:items]]
      )

    (opportunities ++ campaigns)
    |> Enum.sort_by(& &1.delivery_start, Date)
    |> Utils.ordered_group_by(&LocalizedDateTime.to_date(&1.delivery_start))
  end

  defp signup_link(%Campaign{} = campaign) do
    url(~p"/campaigns/signup/#{campaign.id}")
  end

  defp signup_link(%Opportunity{} = opportunity) do
    opportunity.signup_link
  end

  defp hide_address?(%Opportunity{} = opportunity) do
    opportunity.hide_address
  end

  defp hide_address?(%Campaign{} = campaign) do
    campaign.program.hide_pickup_address
  end

  attr :campaign_or_opportunity, :any

  defp show_items(assigns) do
    visible_items_count =
      Enum.count(assigns.campaign_or_opportunity.program.items, fn item -> not item.hidden end)

    if visible_items_count == 0 do
      ~H""
    else
      ~H"""
      <div class="flex items-start text-sm text-gray-300">
        <Heroicons.shopping_bag aria-label="Items" class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" />
        <div class="flex flex-col">
          You'll be delivering:
          <p
            :for={item when not item.hidden <- @campaign_or_opportunity.program.items}
            class="text-sm text-gray-300"
          >
            <span class="font-bold"><%= item.name %></span> - <%= item.description %>
          </p>
        </div>
      </div>
      """
    end
  end
end
