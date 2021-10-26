defmodule BikeBrigadeWeb.CampaignLive.Show do
  use BikeBrigadeWeb, :live_view

  import BikeBrigadeWeb.CampaignHelpers
  import BikeBrigade.Utils, only: [replace_if_updated: 2]
  alias BikeBrigadeWeb.CampaignLive.{TasksListComponent, MapComponent, RidersListComponent}
  alias BikeBrigade.Delivery
  alias BikeBrigade.Delivery.{Campaign, Task, CampaignRider}
  alias BikeBrigade.Riders.Rider

  @impl true
  def mount(_params, session, socket) do
    if connected?(socket) do
      Delivery.subscribe()
    end

    {:ok,
     socket
     |> assign(:page, :campaigns)}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    campaign = Delivery.get_campaign(id)

    {:noreply,
     socket
     |> assign(:page_title, name(campaign))
     |> assign_campaign(campaign)
     |> assign(:selected_task, nil)
     |> assign(:selected_rider, nil)
     |> assign(:tasks_query, %{assignment: "all"})
     |> assign(:riders_query, %{capacity: "all"})
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp assign_campaign(socket, campaign) do
    riders =
      for r <- campaign.riders, into: %{} do
        {r.id, r}
      end

    tasks =
      for t <- campaign.tasks, into: %{} do
        {t.id, t}
      end

    socket
    |> assign(:campaign, campaign)
    |> assign(:riders, riders)
    |> assign(:tasks, tasks)
  end

  defp get_rider(socket, id) when is_binary(id), do: get_rider(socket, String.to_integer(id))
  defp get_rider(socket, id) when is_integer(id), do: socket.assigns.riders[id]

  defp get_task(socket, id) when is_binary(id), do: get_task(socket, String.to_integer(id))
  defp get_task(socket, id) when is_integer(id), do: socket.assigns.tasks[id]

  defp apply_action(socket, :new_task, _) do
    socket
    |> assign(:form_task, %Task{})
  end

  defp apply_action(socket, :edit_task, %{"task_id" => task_id}) do
    task = Delivery.get_task(task_id)

    socket
    |> assign(:form_task, task)
  end

  defp apply_action(socket, _, _), do: socket

  @impl true
  def handle_event("select-task", %{"id" => id}, socket) do
    socket =
      if !same_task?(socket.assigns.selected_task, id) do
        assign(socket, selected_task: get_task(socket, id))
        |> push_event("select-task", %{id: id})
      else
        assign(socket, selected_task: nil)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("auto-assign", _, socket) do
    BikeBrigade.Delivery.hacky_assign(socket.assigns.campaign)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "search-tasks",
        %{"value" => query},
        socket
      ) do
    tasks_query = Map.put(socket.assigns.tasks_query, :search, query)

    {:noreply, socket |> assign(:tasks_query, tasks_query)}
  end

  @impl true
  def handle_event(
        "filter-tasks",
        %{"assignment" => assignment},
        socket
      ) do
    tasks_query = Map.put(socket.assigns.tasks_query, :assignment, assignment)

    {:noreply, socket |> assign(:tasks_query, tasks_query)}
  end

  @impl true
  def handle_event(
        "search-riders",
        %{"value" => query},
        socket
      ) do
    riders_query = Map.put(socket.assigns.riders_query, :search, query)

    {:noreply, socket |> assign(:riders_query, riders_query)}
  end

  @impl true
  def handle_event(
        "filter-riders",
        %{"capacity" => capacity},
        socket
      ) do
    riders_query = Map.put(socket.assigns.riders_query, :capacity, capacity)

    {:noreply, socket |> assign(:riders_query, riders_query)}
  end

  @impl true
  def handle_event("select-rider", %{"id" => id}, socket) do
    socket =
      if !same_rider?(socket.assigns.selected_rider, id) do
        assign(socket, selected_rider: get_rider(socket, id))
        |> push_event("select-rider", %{id: id})
      else
        assign(socket, selected_rider: nil)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("assign-task", %{"task-id" => task_id, "rider-id" => rider_id}, socket) do
    {:ok, _task} =
      get_task(socket, task_id)
      |> Delivery.update_task(%{assigned_rider_id: rider_id})

    {:noreply, socket}
  end

  @impl true
  def handle_event("unassign-task", %{"task-id" => task_id}, socket) do
    task = get_task(socket, task_id)

    if task.assigned_rider do
      {:ok, _task} =
        task
        |> Delivery.update_task(%{assigned_rider_id: nil})
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "change-delivery-status",
        %{"task-id" => task_id, "delivery-status" => delivery_status},
        socket
      ) do
    # TODO some error handling
    task = get_task(socket, task_id)

    Delivery.update_task(task, %{
      delivery_status: delivery_status
    })

    {:noreply, socket}
  end

  @impl true
  def handle_event("resend-message", %{"rider-id" => rider_id}, socket) do
    rider = get_rider(socket, rider_id)

    Delivery.send_campaign_message(socket.assigns.campaign, rider)

    {:noreply, socket}
  end

  @impl true
  def handle_event("remove-rider", %{"rider-id" => rider_id}, socket) do
    rider = get_rider(socket, rider_id)

    Delivery.remove_rider_from_campaign(socket.assigns.campaign, rider)

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete-task", %{"task-id" => task_id}, socket) do
    task = get_task(socket, task_id)
    Delivery.delete_task(task)

    # Deleting here while it should be done when we get the handle info
    # The problem is that the campaign task isn't loaded
    # When i make the campaign_id on the task this will resolve itself.

    campaign =
      socket.assigns.campaign
      |> Map.update!(:tasks, fn tasks -> Enum.reject(tasks, &(&1.id == task.id)) end)
      |> Delivery.preload_campaign()

    {:noreply,
     socket
     |> assign(:campaign, campaign)}
  end

  defmacrop belongs_to_campaign?(campaign, task) do
    quote do
      unquote(task).campaign_id == unquote(campaign).id
    end
  end

  @impl Phoenix.LiveView
  def handle_info({:campaign_updated, %Campaign{id: campaign_id}}, socket)
      when campaign_id == socket.assigns.campaign.id do
    campaign = Delivery.get_campaign(campaign_id)

    {:noreply,
     socket
     |> assign_campaign(campaign)}
  end

  @impl Phoenix.LiveView
  def handle_info({:task_updated, updated_task}, socket)
      when belongs_to_campaign?(socket.assigns.campaign, updated_task) do
    %{campaign: campaign, selected_task: selected_task} = socket.assigns

    campaign =
      campaign
      |> Map.update!(:tasks, &replace_if_updated(&1, updated_task))
      |> Delivery.preload_campaign()

    selected_task = replace_if_updated(selected_task, updated_task)

    {:noreply,
     socket
     |> assign_campaign(campaign)
     |> assign(:selected_task, selected_task)}
  end

  @impl Phoenix.LiveView
  def handle_info({:task_deleted, %Task{id: deleted_id} = deleted_task}, socket)
      when belongs_to_campaign?(socket.assigns.campaign, deleted_task) do
    %{campaign: campaign, selected_task: selected_task} = socket.assigns

    campaign =
      campaign
      |> Map.update!(:tasks, fn tasks -> Enum.reject(tasks, &(&1.id == deleted_task.id)) end)
      |> Delivery.preload_campaign()

    selected_task =
      case selected_task do
        nil -> nil
        %Task{id: ^deleted_id} -> nil
        _ -> selected_task
      end

    {:noreply,
     socket
     |> assign_campaign(campaign)
     |> assign(:selected_task, selected_task)}
  end

  @impl true
  def handle_info(
        {:campaign_rider_deleted,
         %CampaignRider{campaign_id: campaign_id, rider_id: deleted_rider_id}},
        socket
      ) do
    %{campaign: campaign, selected_rider: selected_rider} = socket.assigns

    if campaign_id == campaign.id do
      campaign =
        campaign
        |> Map.update!(:riders, fn riders -> Enum.reject(riders, &(&1.id == deleted_rider_id)) end)
        |> Delivery.preload_campaign()

      selected_rider =
        case selected_rider do
          nil -> nil
          %Rider{id: ^deleted_rider_id} -> nil
          _ -> selected_rider
        end

      {:noreply,
       socket
       |> assign_campaign(campaign)
       |> assign(:selected_rider, selected_rider)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  @doc "silently ignore new kinds of messages"
  def handle_info(_, socket), do: {:noreply, socket}
end
