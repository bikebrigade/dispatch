defmodule BikeBrigadeWeb.CampaignHelpers do
  alias BikeBrigade.Delivery.Task
  alias BikeBrigade.Riders.Rider
  alias BikeBrigade.Delivery
  alias BikeBrigade.Utils

  use BikeBrigadeWeb, :live_component

  alias BikeBrigade.LocalizedDateTime

  def task_assigned?(task) do
    task.assigned_rider != nil
  end

  def rider_available?(rider) do
    Enum.count(rider.assigned_tasks) < rider.task_capacity
  end

  def selected?(%Task{id: id}, %Task{id: id}), do: true
  def selected?(%Rider{id: id}, %Rider{id: id}), do: true
  def selected?(_, _), do: false

  def same_task?(%Task{id: id}, id), do: true

  def same_task?(%Task{id: id}, str_id) when is_binary(str_id),
    do: Integer.to_string(id) == str_id

  def same_task?(_, _), do: false

  def rider_task?(%Rider{assigned_tasks: assigned_tasks}, %Task{id: task_id}),
    do: task_id in Enum.map(assigned_tasks, & &1.id)

  def rider_task?(_, _), do: false

  def task_rider?(%Task{assigned_rider_id: rider_id}, %Rider{id: rider_id}), do: true
  def task_rider?(_, _), do: false

  def filter_tasks(%{} = tasks, query) do
    tasks =
      case query[:assignment] do
        "all" -> tasks
        "assigned" -> filter_map(tasks, &task_assigned?/1)
        "unassigned" -> filter_map(tasks, &(!task_assigned?(&1)))
        _ -> tasks
      end

    if query[:search] && query[:search] != "" do
      filter_map(tasks, fn task ->
        task.dropoff_name =~ ~r/#{Regex.escape(query[:search])}/i or
          task.dropoff_location.address =~ ~r/#{Regex.escape(query[:search])}/i
      end)
    else
      tasks
    end
  end

  def filter_riders(%{} = riders, query) do
    riders =
      case query[:capacity] do
        "all" -> riders
        "available" -> filter_map(riders, &rider_available?/1)
        _ -> riders
      end

    if query[:search] && query[:search] != "" do
      filter_map(
        riders,
        &String.contains?(String.downcase(&1.name), String.downcase(query[:search]))
      )
    else
      riders
    end
  end

  defp filter_map(map, filter?) do
    for {k, v} <- map, filter?.(v), into: %{}, do: {k, v}
  end

  def has_notes?(%Rider{task_notes: nil}), do: false
  def has_notes?(%Rider{task_notes: notes}), do: String.trim(notes) != ""

  def pickup_window(campaign) do
    # TODO bad place for the helper
    BikeBrigadeWeb.LiveHelpers.time_interval(campaign.delivery_start, campaign.delivery_end)
  end

  def pickup_window(campaign, rider) do
    if rider.pickup_window do
      rider.pickup_window
    else
      pickup_window(campaign)
    end
  end

  def name(campaign) do
    if campaign.program do
      campaign.program.name
    else
      campaign.name
    end
  end

  def public?(campaign) do
    campaign.program.public
  end

  def campaign_date(campaign) do
    LocalizedDateTime.to_date(campaign.delivery_start)
  end

  def request_type(task) do
    if task.task_items != [] do
      task.task_items
      |> Enum.map(&print_item/1)
      |> Enum.join(", ")
    else
      "None"
    end
  end

  def campaign_in_past(campaign) do
    date_now = DateTime.utc_now()

    case DateTime.compare(campaign.delivery_end, date_now) do
      :gt -> false
      :eq -> false
      :lt -> true
    end
  end

  # TODO this could be better
  defp print_item(task_item) do
    "#{task_item.count} #{Inflex.inflect(task_item.item.name, task_item.count)}"
  end

  attr :filled_tasks, :integer, required: true
  attr :total_tasks, :integer, required: true
  attr :campaign, :any, required: true

  @doc """
    Renders possible states of campaign "Fullness" in styled text.
  """
  def tasks_filled_text(assigns) do
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
    <p class="flex flex-col items-center mt-0 text-sm text-gray-700 md:flex-row">
      <Icons.maki_bicycle_share class="flex-shrink-0 mb-2 mr-1.5 h-8 w-8 md:h-5 md:w-5 md:mb-0 text-gray-500" />
      <span class="flex space-x-2 font-bold md:font-normal">
        <span class={@class}><%= @copy %></span>
      </span>
    </p>
    """
  end

  # Use this to determine if we need to refetch data to update the liveview.
  # ex: dispatcher changes riders/tasks, or another rider signs up -> refetch.
  def entity_in_campaigns?(campaigns, entity_campaign_id) do
    campaigns
    |> Enum.flat_map(fn {_date, campaigns} -> campaigns end)
    |> Enum.any?(fn c -> c.id == entity_campaign_id end)
  end
end
