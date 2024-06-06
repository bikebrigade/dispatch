defmodule BikeBrigadeWeb.CampaignLive.Index do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.Utils
  alias BikeBrigade.LocalizedDateTime

  alias BikeBrigade.Delivery
  alias BikeBrigade.Delivery.Campaign
  alias BikeBrigade.Messaging.SmsMessage
  alias BikeBrigadeWeb.Components.CampaignComponents

  import BikeBrigadeWeb.CampaignHelpers

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Delivery.subscribe()
    end

    current_week =
      LocalizedDateTime.today()
      |> Date.beginning_of_week()

    {:ok,
     socket
     |> assign(:page, :campaigns)
     |> assign(:page_title, "Campaigns")
     |> assign(:current_week, current_week)
     |> assign(:campaigns, fetch_campaigns(current_week))
     |> assign(:campaign_task_counts, Delivery.get_total_tasks_and_open_tasks(current_week))
    }
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @broadcasted_infos [
    :task_created,
    :task_deleted,
    :task_updated,
    :campaign_rider_created,
    :campaign_rider_deleted
  ]

  @impl Phoenix.LiveView
  def handle_info({event, entity}, socket) when event in @broadcasted_infos do
    if entity_in_campaigns?(socket.assigns.campaigns, entity.campaign_id) do
      {:noreply, refetch_and_assign_data(socket)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    campaign = Delivery.get_campaign(id)
    {:ok, _} = Delivery.delete_campaign(campaign)

    {:noreply, assign(socket, :campaigns, fetch_campaigns(socket.assigns.current_week))}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Campaign")
    |> assign(:campaign, Delivery.get_campaign(id))
  end

  defp apply_action(socket, :new, _params) do
    campaign = Delivery.new_campaign()

    socket
    |> assign(:page_title, "New Campaign")
    |> assign(:campaign, campaign)
  end

  defp apply_action(socket, :duplicate, %{"id" => id}) do
    socket
    |> assign(:page_title, "Duplicate Campaign")
    |> assign(:campaign, Delivery.get_campaign(id))
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
    Delivery.list_campaigns(
      start_date: current_week,
      end_date: Date.add(current_week, 6),
      preload: [:program, :stats, :latest_message, :scheduled_message]
    )
    |> Enum.reverse()
    |> Utils.ordered_group_by(&LocalizedDateTime.to_date(&1.delivery_start))
    |> Enum.reverse()
  end

  attr :campaign, Campaign, required: true

  def message_info(%{campaign: %Campaign{scheduled_message: %{send_at: send_at}}} = assigns)
      when not is_nil(send_at) do
    assigns = assign(assigns, :send_at, send_at)

    ~H"""
    <Heroicons.clock mini class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-500" />
    <p>
      Message scheduled for
      <time datetime={@send_at}>
        <%= datetime(@send_at) %>
      </time>
    </p>
    """
  end

  def message_info(
        %{campaign: %Campaign{latest_message: %SmsMessage{sent_at: sent_at}}} = assigns
      ) do
    assigns = assign(assigns, :sent_at, sent_at)

    ~H"""
    <Heroicons.chat_bubble_left_right mini class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-500" />
    <p>
      Last messaged at
      <time datetime={@sent_at}>
        <%= datetime(@sent_at) %>
      </time>
    </p>
    """
  end

  def message_info(assigns) do
    ~H""
  end

  defp refetch_and_assign_data(socket) do
    week = socket.assigns.current_week

    socket
    |> assign(:campaign_task_counts, Delivery.get_total_tasks_and_open_tasks(week))
    |> assign(:campaigns, fetch_campaigns(week))
  end
end
