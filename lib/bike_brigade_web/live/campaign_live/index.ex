defmodule BikeBrigadeWeb.CampaignLive.Index do
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
     |> assign(:page_title, "Campaigns")
     |> assign(:current_week, current_week)
     |> assign(:campaigns, fetch_campaigns(current_week))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    campaign = Delivery.get_campaign(id)
    {:ok, _} = Delivery.delete_campaign(campaign)

    {:noreply, assign(socket, :campaigns, fetch_campaigns(socket.assigns.current_week))}
  end

  @impl true
  def handle_event("next-week", _params, socket) do
    current_week = Date.add(socket.assigns.current_week, 7)

    {:noreply,
     assign(socket, current_week: current_week, campaigns: fetch_campaigns(current_week))}
  end

  @impl true
  def handle_event("prev-week", _params, socket) do
    current_week = Date.add(socket.assigns.current_week, -7)

    {:noreply,
     assign(socket, current_week: current_week, campaigns: fetch_campaigns(current_week))}
  end

  @impl true
  def handle_event("this-week", _params, socket) do
    current_week =
      LocalizedDateTime.today()
      |> Date.beginning_of_week()

    {:noreply,
     assign(socket, current_week: current_week, campaigns: fetch_campaigns(current_week))}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Campaign")
    |> assign(:campaign, Delivery.get_campaign(id))
  end

  defp apply_action(socket, :new, _params) do
    today = LocalizedDateTime.today()
    start_time = ~T[17:00:00]
    end_time = ~T[19:30:00]

    delivery_start = LocalizedDateTime.new!(today, start_time)
    delivery_end = LocalizedDateTime.new!(today, end_time)

    socket
    |> assign(:page_title, "New Campaign")
    |> assign(:campaign, %Campaign{delivery_start: delivery_start, delivery_end: delivery_end})
  end

  defp apply_action(socket, :duplicate, %{"id" => id}) do
    socket
    |> assign(:page_title, "Duplicate Campaign")
    |> assign(:campaign, Delivery.get_campaign(id))
  end

  defp apply_action(socket, :index, _params) do
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

  def message_info(assigns) do
    case assigns.campaign do
      %{scheduled_message: %{send_at: send_at}} when not is_nil(send_at) ->
        ~H"""
        <Heroicons.Solid.clock class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" />
        <p>
          Message scheduled for
          <time datetime={send_at}>
            <%= datetime(send_at) %>
          </time>
        </p>
        """

      %{latest_message: %SmsMessage{sent_at: sent_at}} ->
        ~H"""
        <Heroicons.Solid.chat_alt_2 class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" />
        <p>
          Last messaged at
          <time datetime={sent_at}>
            <%= datetime(sent_at) %>
          </time>
        </p>
        """

      _ ->
        ~H""
    end
  end
end
