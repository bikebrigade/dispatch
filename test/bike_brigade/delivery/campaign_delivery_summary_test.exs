defmodule BikeBrigade.Delivery.CampaignDeliverySummaryTest do
  use BikeBrigade.DataCase

  alias BikeBrigade.{Delivery, LocalizedDateTime}

  alias BikeBrigade.Delivery.CampaignDeliverySummary, as: CDS

  test "validate the initial structure" do
    assert %CDS{completed: 0, total: 0, unassigned: [], assigned: %{}} == CDS.new()
  end

  describe "add_task/2" do
    setup do
      program = fixture(:program, %{name: "ACME Delivery"})

      campaign =
        fixture(:campaign, %{
          program_id: program.id,
          delivery_start: LocalizedDateTime.localize(~N[2023-01-01 10:00:00]),
          delivery_end: LocalizedDateTime.localize(~N[2023-01-01 11:00:00])
        })

      rider = fixture(:rider, %{name: "Hannah Bannana"})
      task = fixture(:task, %{campaign: campaign, rider: rider})
      unassigned_task = fixture(:task, %{campaign: campaign})
      preload_unassigned_task = Delivery.get_task(unassigned_task.id)
      {:ok, completed_task} = Delivery.mark_task_complete_by_rider(task.id, rider.id)
      %{completed_task: completed_task, unassigned_task: preload_unassigned_task}
    end

    test "validate single completed task count", %{completed_task: completed_task} do
      cds = CDS.new()
      original_completed = cds.completed
      updated_cds = CDS.add_task(cds, completed_task)
      assert updated_cds.completed == original_completed + 1
    end

    test "validate single task count", %{completed_task: completed_task} do
      cds = CDS.new()
      original_total = cds.total
      updated_cds = CDS.add_task(cds, completed_task)
      assert updated_cds.total == original_total + 1
    end

    test "validate empty unassigned task", %{completed_task: completed_task} do
      cds = CDS.new()
      original_unassigned = cds.unassigned
      updated_cds = CDS.add_task(cds, completed_task)
      assert updated_cds.unassigned == original_unassigned
    end

    test "validate assigned completed task contains rider name as key", %{
      completed_task: completed_task
    } do
      rider_name = completed_task.assigned_rider.name
      updated_cds = CDS.new() |> CDS.add_task(completed_task)
      assert Map.has_key?(updated_cds.assigned, rider_name)
    end

    test "validate assigned completed task details", %{completed_task: completed_task} do
      rider_name = completed_task.assigned_rider.name
      task_item_names = Enum.map_join(completed_task.task_items, ", ", & &1.item.name)

      updated_cds = CDS.new() |> CDS.add_task(completed_task)
      [delivery_details] = Map.get(updated_cds.assigned, rider_name)
      assert delivery_details.dropoff_name == completed_task.dropoff_name
      assert delivery_details.items == task_item_names
    end

    test "validate unassigned task with single task", %{unassigned_task: unassigned_task} do
      updated_cds = CDS.new() |> CDS.add_task(unassigned_task)
      assert length(updated_cds.unassigned) == 1
    end

    test "validate items in unassigned single task", %{unassigned_task: unassigned_task} do
      task_item_names = Enum.map_join(unassigned_task.task_items, ", ", & &1.item.name)

      updated_cds = CDS.new() |> CDS.add_task(unassigned_task)
      [delivery_details] = updated_cds.unassigned
      assert delivery_details.dropoff_name == unassigned_task.dropoff_name
      assert delivery_details.items == task_item_names
    end
  end
end
