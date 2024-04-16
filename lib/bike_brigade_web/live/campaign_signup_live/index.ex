defmodule BikeBrigadeWeb.CampaignSignupLive.Index do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.Utils
  alias BikeBrigade.LocalizedDateTime
  alias BikeBrigade.Delivery

  import BikeBrigadeWeb.CampaignHelpers

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Delivery.subscribe()
    end

    current_week =
      LocalizedDateTime.today()
      |> Date.beginning_of_week()

    campaigns = fetch_campaigns(current_week)

    {:ok,
     socket
     |> assign(:page, :campaigns_signup)
     |> assign(:page_title, "Delivery Sign Up")
     |> assign(:current_week, current_week)
     |> assign(:campaign_task_counts, Delivery.get_total_tasks_and_open_tasks(current_week))
     |> assign(:showing_urgent_campaigns, false)
     |> assign(:campaigns, campaigns)}
  end

  @impl true
  def handle_params(%{"campaign_ids" => campaign_ids}, _url, socket) do
    campaigns = fetch_campaigns(socket.assigns.current_week, campaign_ids: campaign_ids)

    {:noreply,
     socket
     |> assign(:campaigns, campaigns)
     |> assign(:showing_urgent_campaigns, true)}
  end

  def handle_params(params, _url, socket) do
    {:noreply,
      socket
      |> assign(:showing_urgent_campaigns, false)
      |> apply_action(socket.assigns.live_action, params)}
  end

  # -- Delivery callbacks

  @broadcasted_infos [
    :task_created,
    :task_deleted,
    :task_updated,
    :campaign_rider_created,
    :campaign_rider_deleted
  ]

  @impl Phoenix.LiveView
  def handle_info({event, entity}, socket) when event in @broadcasted_infos do
    if entity_in_campaigns?(socket, entity.campaign_id) do
      {:noreply, refetch_and_assign_data(socket)}
    else
      {:noreply, socket}
    end
  end

  ## -- End Delivery callbacks

  defp apply_action(socket, :index, params) do
    socket =
      case params do
        %{"current_week" => week} ->
          week = Date.from_iso8601!(week)

          assign(socket,
            current_week: week,
            campaigns: fetch_campaigns(week),
            campaign_task_counts: Delivery.get_total_tasks_and_open_tasks(week)
          )

        _ ->
          socket
      end

    socket
    |> assign(:campaign, nil)
  end

  defp fetch_campaigns(current_week, opts \\ []) do
    Delivery.list_campaigns(current_week,
      preload: [:program, :stats, :latest_message, :scheduled_message],
      campaign_ids: opts[:campaign_ids]
    )
    |> Enum.reverse()
    |> Utils.ordered_group_by(&LocalizedDateTime.to_date(&1.delivery_start))
    |> Enum.reverse()
  end

  # TODO HACK: right now everytime something about a task, or campaign rider
  # changes (add, edit, delete), we refetch all tasks and campaign riders.
  # This may eventually become a problem.
  defp refetch_and_assign_data(socket) do
    week = socket.assigns.current_week

    socket
    |> assign(:campaign_task_counts, Delivery.get_total_tasks_and_open_tasks(week))
    |> assign(:campaigns, fetch_campaigns(week))
  end

  # Use this to determine if we need to refetch data to update the liveview.
  # ex: dispatcher changes riders/tasks, or another rider signs up -> refetch.
  defp entity_in_campaigns?(socket, entity_campaign_id) do
    socket.assigns.campaigns
    |> Enum.flat_map(fn {_date, campaigns} -> campaigns end)
    |> Enum.any?(fn c -> c.id == entity_campaign_id end)
  end

  attr :filled_tasks, :integer, required: true
  attr :total_tasks, :integer, required: true
  attr :campaign, :any, required: true

  defp tasks_filled_text(assigns) do
    {class, copy} =
      cond do
        assigns.filled_tasks == nil ->
          {"text-gray-600", "N/A"}

        campaign_in_past(assigns.campaign) ->
          {"text-gray-600", "Campaign over"}

        assigns.total_tasks - assigns.filled_tasks == 0 ->
          {"text-gray-600", "Fully Assigned"}

        true ->
          {"text-red-400", "#{assigns.total_tasks - assigns.filled_tasks} Available"}
      end

    assigns =
      assigns
      |> assign(:class, class)
      |> assign(:copy, copy)

    ~H"""
    <p class="flex flex-col md:flex-row items-center mt-0 text-sm text-gray-700">
      <Icons.maki_bicycle_share class="flex-shrink-0 mb-2 mr-1.5 h-8 w-8 md:h-5 md:w-5 md:mb-0 text-gray-500" />
      <span class="flex space-x-2 font-bold md:font-normal">
        <span class={@class}><%= @copy %></span>
      </span>
    </p>
    """
  end

  attr :campaign, :any, required: true
  attr :rider_id, :integer, required: true
  attr :campaign_task_counts, :any, required: true

  defp signup_button(assigns) do
    c = assigns.campaign
    filled_tasks = assigns.campaign_task_counts[c.id][:filled_tasks]
    total_tasks = assigns.campaign_task_counts[c.id][:total_tasks]
    campaign_tasks_fully_assigned? = filled_tasks == total_tasks
    campaign_not_ready_for_signup? = is_nil(total_tasks)

    current_rider_task_count =
      if is_nil(total_tasks) do
        0
      else
        assigns.campaign_task_counts[c.id].rider_ids_counts[assigns.rider_id] || 0
      end

    campaign_in_past = campaign_in_past(assigns.campaign)

    # Define map for button properties
    buttonType =
      cond do
        campaign_in_past ->
          %{color: :disabled, text: "Completed"}

        current_rider_task_count > 0 ->
          %{color: :secondary, text: "Signed up for #{current_rider_task_count} deliveries"}

        campaign_not_ready_for_signup? ->
          %{color: :disabled, text: "Campaign not ready for signup"}

        campaign_tasks_fully_assigned? ->
          %{color: :secondary, text: "Campaign Filled"}

        true ->
          %{color: :secondary, text: "Sign up"}
      end

    assigns =
      assigns
      |> assign(:signup_text, Map.get(buttonType, :text))
      |> assign(:button_color, Map.get(buttonType, :color))

    ~H"""
    <.button
      size={:small}
      class="w-full rounded-none md:rounded-sm"
      color={@button_color}
      navigate={~p"/campaigns/signup/#{@campaign}/"}
    >
      <%= @signup_text %>
    </.button>
    """
  end
end
