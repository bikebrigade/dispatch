defmodule BikeBrigadeWeb.CampaignHelpers do
  alias BikeBrigade.Delivery.Task
  alias BikeBrigade.Riders.Rider

  alias BikeBrigade.LocalizedDateTime

  def task_assigned?(task) do
    task.assigned_rider != nil || task.onfleet_pickup_id != nil
  end

  def rider_available?(rider) do
    Enum.count(rider.assigned_tasks) < rider.task_capacity
  end

  def selected?(%Task{id: id}, %Task{id: id}), do: true
  def selected?(%Rider{id: id}, %Rider{id: id}), do: true
  def selected?(_, _), do: false

  def same_rider?(%Rider{id: id}, id), do: true

  def same_rider?(%Rider{id: id}, str_id) when is_binary(str_id),
    do: Integer.to_string(id) == str_id

  def same_rider?(_, _), do: false

  def same_task?(%Task{id: id}, id), do: true

  def same_task?(%Task{id: id}, str_id) when is_binary(str_id),
    do: Integer.to_string(id) == str_id

  def same_task?(_, _), do: false

  def rider_task?(%Rider{assigned_tasks: assigned_tasks}, %Task{id: task_id}),
    do: task_id in Enum.map(assigned_tasks, & &1.id)

  def rider_task?(_, _), do: false

  def task_rider?(%Task{assigned_rider_id: rider_id}, %Rider{id: rider_id}), do: true
  def task_rider?(_, _), do: false

  def filter_tasks(tasks, query) do
    tasks =
      case query[:assignment] do
        "all" -> tasks
        "assigned" -> Enum.filter(tasks, &task_assigned?(&1))
        "unassigned" -> Enum.filter(tasks, &(!task_assigned?(&1)))
        _ -> tasks
      end

    if query[:search] && query[:search] != "" do
      Enum.filter(
        tasks,
        fn t ->
          t.dropoff_name =~ ~r/#{Regex.escape(query[:search])}/i or
            t.dropoff_address =~ ~r/#{Regex.escape(query[:search])}/i
        end
      )
    else
      tasks
    end
  end

  def filter_riders(riders, query) do
    riders =
      case query[:capacity] do
        "all" -> riders
        "available" -> Enum.filter(riders, &rider_available?(&1))
        _ -> riders
      end

    if query[:search] && query[:search] != "" do
      Enum.filter(
        riders,
        &String.contains?(String.downcase(&1.name), String.downcase(query[:search]))
      )
    else
      riders
    end
  end

  def has_notes?(%Rider{task_notes: nil}), do: false
  def has_notes?(%Rider{task_notes: notes}), do: String.trim(notes) != ""

  def pickup_window(campaign, rider) do
    cond do
      rider.pickup_window ->
        rider.pickup_window

      # TODO bad place for the helper!
      campaign.delivery_start ->
        BikeBrigadeWeb.LiveHelpers.time_interval(campaign.delivery_start, campaign.delivery_end)

      true ->
        campaign.pickup_window
    end
  end

  def name(campaign) do
    campaign = campaign

    if campaign.program do
      campaign.program.name
    else
      campaign.name
    end
  end

  # TODO: this is no-longer needed as all campaigns have delivery_start now
  def campaign_date(campaign) do
    if campaign.delivery_start do
      LocalizedDateTime.to_date(campaign.delivery_start)
    else
      campaign.delivery_date
    end
  end

  def request_type(task) do
    if task.task_items != [] do
      task.task_items
      |> Enum.map(&print_item/1)
      |> Enum.join(", ")
    else
      task.request_type
    end
  end

  # TODO this could be better
  defp print_item(task_item) do
    if task_item.count == 1 do
      "#{task_item.count} #{task_item.item.name}"
    else
      "#{task_item.count} #{task_item.item.plural_name}"
    end
  end
end
