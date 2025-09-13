defmodule BikeBrigadeWeb.CampaignSignupLive.Index do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.Utils
  alias BikeBrigade.LocalizedDateTime
  alias BikeBrigade.Delivery
  alias BikeBrigade.Delivery.{Opportunity, Campaign}

  import BikeBrigadeWeb.CampaignHelpers

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Delivery.subscribe()
    end

    current_week =
      LocalizedDateTime.today()
      |> Date.beginning_of_week()

    campaign_filter = {:current_week, current_week}

    campaigns_and_opportunities = fetch_campaigns_and_opportunities(campaign_filter)
    start_date = LocalizedDateTime.new!(current_week, ~T[00:00:00])
    end_date = Date.add(current_week, 6) |> LocalizedDateTime.new!(~T[23:59:59])

    {:ok,
     socket
     |> assign(:page, :campaigns_signup)
     |> assign(:page_title, "Delivery Sign Up")
     |> assign(:current_week, current_week)
     |> assign(:campaign_filter, campaign_filter)
     |> assign(
       :campaign_task_counts,
       Delivery.get_total_tasks_and_open_tasks(start_date, end_date)
     )
     |> assign(:showing_urgent_campaigns, false)
     |> assign(:campaigns_and_opportunities, campaigns_and_opportunities)}
  end

  @impl true
  def handle_params(%{"campaign_ids" => campaign_ids}, _url, socket) do
    campaign_filter = {:campaign_ids, campaign_ids}
    # We are joining campaigns and opportunities so that they can be displayed
    # as a intermixed list of things that people can sign up for.
    # This is why you will see a lot of long variables. Sorry.
    campaigns_and_opportunities = fetch_campaigns_and_opportunities(campaign_filter)

    start_date = LocalizedDateTime.now()
    end_date = Date.add(start_date, 2) |> LocalizedDateTime.new!(~T[23:59:59])

    {:noreply,
     socket
     |> assign(:campaigns_and_opportunities, campaigns_and_opportunities)
     |> assign(:campaign_filter, campaign_filter)
     |> assign(
       :campaign_task_counts,
       Delivery.get_total_tasks_and_open_tasks(start_date, end_date)
     )
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

  @impl Phoenix.LiveView
  @doc "silently ignore other kinds of messages"
  def handle_info(_, socket), do: {:noreply, socket}

  ## -- End Delivery callbacks

  defp apply_action(socket, :index, params) do
    socket =
      case params do
        %{"current_week" => week} ->
          week = Date.from_iso8601!(week)
          campaign_filter = {:current_week, week}

          assign(socket,
            current_week: week,
            campaign_filter: campaign_filter,
            campaigns_and_opportunities: fetch_campaigns_and_opportunities(campaign_filter),
            campaign_task_counts: Delivery.get_total_tasks_and_open_tasks(week)
          )

        _ ->
          socket
      end

    socket
    |> assign(:campaign, nil)
  end

  defp fetch_campaigns_and_opportunities({:campaign_ids, campaign_ids}) do
    Delivery.list_campaigns(
      campaign_ids: campaign_ids,
      preload: [:program, :latest_message, :scheduled_message],
      public: true
    )
    |> Enum.reverse()
    |> Utils.ordered_group_by(&LocalizedDateTime.to_date(&1.delivery_start))
  end

  defp fetch_campaigns_and_opportunities({:current_week, current_week}) do
    opportunities =
      Delivery.list_opportunities(
        start_date: current_week,
        end_date: Date.add(current_week, 6),
        published: true,
        preload: [location: [:neighborhood], program: [:items]]
      )

    campaigns =
      Delivery.list_campaigns(
        start_date: current_week,
        end_date: Date.add(current_week, 6),
        public: true,
        preload: [:program, :latest_message, :scheduled_message]
      )

    (opportunities ++ campaigns)
    |> Enum.sort_by(& &1.delivery_start, Date)
    |> Utils.ordered_group_by(&LocalizedDateTime.to_date(&1.delivery_start))
  end

  # TODO HACK: right now everytime something about a task, or campaign rider
  # changes (add, edit, delete), we refetch all tasks and campaign riders.
  # This may eventually become a problem.
  defp refetch_and_assign_data(socket) do
    campaign_filter = socket.assigns.campaign_filter
    week = socket.assigns.current_week

    socket
    |> assign(:campaign_task_counts, Delivery.get_total_tasks_and_open_tasks(week))
    |> assign(:campaigns_and_opportunities, fetch_campaigns_and_opportunities(campaign_filter))
  end

  # Use this to determine if we need to refetch data to update the liveview.
  # ex: dispatcher changes riders/tasks, or another rider signs up -> refetch.
  defp entity_in_campaigns?(socket, entity_campaign_id) do
    socket.assigns.campaigns_and_opportunities
    |> Enum.flat_map(fn {_date, campaigns_and_opportunities} -> campaigns_and_opportunities end)
    |> Enum.any?(fn c_or_o -> match?(%Campaign{}, c_or_o) and c_or_o.id == entity_campaign_id end)
  end

  attr :filled_tasks, :integer, required: true
  attr :total_tasks, :integer, required: true
  attr :campaign_or_opportunity, :any, required: true

  defp tasks_filled_text(assigns) do
    {class, copy} =
      cond do
        match?(%Opportunity{}, assigns.campaign_or_opportunity) ->
          {"text-gray-600", ""}

        assigns.filled_tasks == nil ->
          {"text-gray-600", "N/A"}

        campaign_in_past(assigns.campaign_or_opportunity) ->
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
    <p class="flex flex-col items-center mt-0 text-sm text-gray-700 md:flex-row">
      <Icons.maki_bicycle_share class="flex-shrink-0 mb-2 mr-1.5 h-8 w-8 md:h-5 md:w-5 md:mb-0 text-gray-500" />
      <span class="flex space-x-2 font-bold md:font-normal">
        <span class={@class}>{@copy}</span>
      </span>
    </p>
    """
  end

  defp campaign_or_opportunity_element_id(%Opportunity{id: id}) do
    "opportunity-#{id}"
  end

  defp campaign_or_opportunity_element_id(%Campaign{id: id}) do
    "campaign-#{id}"
  end

  attr :campaign_or_opportunity, :any, required: true
  attr :rider_id, :integer, required: true
  attr :campaign_task_counts, :any, required: true

  defp signup_button(assigns) do
    c_or_o = assigns.campaign_or_opportunity

    {button_type, signup_link} =
      case c_or_o do
        %Opportunity{signup_link: signup_link} ->
          button_type =
            if campaign_in_past(c_or_o) do
              %{color: :disabled, text: "Completed"}
            else
              %{color: :secondary, text: "Sign up"}
            end

          {button_type, signup_link}

        %Campaign{} ->
          filled_tasks = assigns.campaign_task_counts[c_or_o.id][:filled_tasks]
          total_tasks = assigns.campaign_task_counts[c_or_o.id][:total_tasks]
          campaign_tasks_fully_assigned? = filled_tasks == total_tasks
          campaign_not_ready_for_signup? = match?(%Campaign{}, c_or_o) and is_nil(total_tasks)

          current_rider_task_count =
            if is_nil(total_tasks) do
              0
            else
              assigns.campaign_task_counts[c_or_o.id].rider_ids_counts[assigns.rider_id] || 0
            end

          # Define map for button properties
          button_type =
            cond do
              campaign_in_past(c_or_o) ->
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

          {button_type, ~p"/campaigns/signup/#{c_or_o}/"}
      end

    assigns =
      assigns
      |> assign(:button_type, button_type)
      |> assign(:signup_link, signup_link)

    ~H"""
    <.button
      size={:small}
      class="w-full rounded-none md:rounded-sm"
      color={@button_type.color}
      navigate={@signup_link}
    >
      {@button_type.text}
    </.button>
    """
  end
end
