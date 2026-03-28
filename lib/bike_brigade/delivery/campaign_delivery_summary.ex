defmodule BikeBrigade.Delivery.CampaignDeliverySummary do
  defstruct total: 0, completed: 0, assigned: %{}, unassigned: []

  @spec new() :: %BikeBrigade.Delivery.CampaignDeliverySummary{
          assigned: %{},
          completed: 1,
          total: 0,
          unassigned: []
        }
  def new(), do: %__MODULE__{}

  def add_task(cds, task) do
    cds
    |> Map.update!(:total, &(&1 + 1))
    |> completed(task)
    |> delivery(task)
  end

  defimpl Collectable do
    defp collect(cds, {:cont, task}), do: @for.add_task(cds, task)
    defp collect(cds, :done), do: cds
    defp collect(_cds, :halt), do: :ok
    def into(tasks), do: {tasks, &collect/2}
  end

  defp completed(summary, %{delivery_status: :completed}),
    do: Map.update!(summary, :completed, &(&1 + 1))

  defp completed(%{completed: _completed} = summary, _task), do: summary

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
