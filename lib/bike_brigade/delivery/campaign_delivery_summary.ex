defmodule BikeBrigade.Delivery.CampaignDeliverySummary do
  @moduledoc """
  A struct that aggregates delivery task statistics for a campaign.

  Used to generate summaries for Slack notifications after campaigns end.
  Tracks total tasks, completed tasks, and groups deliveries by assigned rider
  or as unassigned.

  Implements the `Collectable` protocol, allowing tasks to be collected into
  a summary using `Enum.into/2`:

      summary = Enum.into(tasks, CampaignDeliverySummary.new(campaign))

  ## Fields

    * `:name` - The program name
    * `:campaign_id` - The campaign ID
    * `:delivery_start` - Campaign delivery start time
    * `:delivery_end` - Campaign delivery end time
    * `:total` - Total number of tasks
    * `:completed` - Number of completed tasks
    * `:assigned` - Map of rider names to their assigned delivery summaries
    * `:unassigned` - List of unassigned delivery summaries
  """

  alias BikeBrigade.Delivery

  defstruct name: nil,
            campaign_id: nil,
            delivery_start: nil,
            delivery_end: nil,
            total: 0,
            completed: 0,
            assigned: %{},
            unassigned: []

  @doc "Creates an empty campaign delivery summary."
  def new(), do: %__MODULE__{}

  @doc "Creates a campaign delivery summary initialized with campaign metadata."
  def new(campaign) do
    %__MODULE__{
      name: campaign.program.name,
      campaign_id: campaign.id,
      delivery_start: campaign.delivery_start,
      delivery_end: campaign.delivery_end
    }
  end

  @doc "Adds a task to the summary, updating totals and assignment tracking."
  def add_task(cds, task) do
    cds
    |> Map.update!(:total, &(&1 + 1))
    |> completed(task)
    |> delivery(task)
  end

  def create_for(campaign) do
    {_riders, tasks} = Delivery.campaign_riders_and_tasks(campaign)
    Enum.into(tasks, new(campaign))
  end

  defimpl Collectable do
    defp collect(cds, {:cont, task}), do: @for.add_task(cds, task)
    defp collect(cds, :done), do: cds
    defp collect(_cds, :halt), do: :ok
    def into(tasks), do: {tasks, &collect/2}
  end

  defp completed(summary, %{delivery_status: :completed}),
    do: Map.update!(summary, :completed, &(&1 + 1))

  defp completed(%__MODULE__{completed: _completed} = summary, _task), do: summary

  defp delivery(summary, %{assigned_rider_id: nil} = task) do
    Map.update!(summary, :unassigned, &append(&1, task))
  end

  defp delivery(summary, task) do
    Map.update!(summary, :assigned, &append_assigned(&1, task))
  end

  defp append_assigned(assigned, %{assigned_rider: %{name: name}} = task) do
    assigned
    |> Map.put_new(name, [])
    |> Map.update!(name, &[delivery_summary(task) | &1])
  end

  defp append(acc, task), do: [delivery_summary(task) | acc]

  defp delivery_summary(%{
         dropoff_name: dropoff_name,
         delivery_status: delivery_status,
         task_items: task_items
       }) do
    %{
      dropoff_name: dropoff_name,
      delivery_status: delivery_status,
      items: Enum.map_join(task_items, ", ", & &1.item.name)
    }
  end
end
