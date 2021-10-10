defmodule BikeBrigadeWeb.CampaignLive.TasksListComponent do
  use BikeBrigadeWeb, :live_component
  require Logger

  alias BikeBrigade.Delivery

  import BikeBrigadeWeb.CampaignHelpers

  @impl true
  def update(assigns, socket) do
    %{campaign: campaign, tasks_query: tasks_query} = assigns

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:tasks_list, filter_tasks(campaign.tasks, tasks_query))}
  end

  @impl true
  def handle_event(
        "update-delivery-status",
        %{"task-id" => task_id, "delivery-status" => delivery_status},
        socket
      ) do
    # TODO some error handling
    task = Delivery.get_task(task_id)

    Delivery.update_task(task, %{
      delivery_status: delivery_status,
    })

    {:noreply, socket}
  end
end
