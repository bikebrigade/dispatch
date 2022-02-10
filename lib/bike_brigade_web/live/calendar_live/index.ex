defmodule BikeBrigadeWeb.CalendarLive.Index do
  use BikeBrigadeWeb, {:live_view, layout: {BikeBrigadeWeb.LayoutView, "public.live.html"}}

  alias BikeBrigade.Utils
  alias BikeBrigade.Delivery
  alias BikeBrigade.LocalizedDateTime

  alias BikeBrigadeWeb.DeliveryHelpers

  @impl true
  def mount(_params, _session, socket) do
    # if connected?(socket) do
    #  Delivery.subscribe()
    # end

    start_date = today = LocalizedDateTime.today()
    opportunities = list_opportunities(start_date)

    end_date =
      case List.last(opportunities) do
        {end_date, _} -> end_date
        nil -> start_date
      end

    {:ok,
     socket
     |> assign(:show_buttons, false)
     |> assign(:today, today)
     |> assign(:start_date, start_date)
     |> assign(:end_date, end_date)
     |> assign(:opportunities, list_opportunities(start_date))}
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

  def list_opportunities(start_date) do
    Delivery.list_opportunities(start_date: start_date, published: true, preload: [ program: [:latest_campaign, :items]])
    |> Utils.ordered_group_by(&LocalizedDateTime.to_date(&1.delivery_start))
  end
end
