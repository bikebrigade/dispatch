defmodule BikeBrigadeWeb.CampaignLive.Show do
  use BikeBrigadeWeb, :live_view

  import BikeBrigadeWeb.CampaignHelpers
  import BikeBrigade.Utils, only: [replace_if_updated: 2]
  alias BikeBrigadeWeb.CampaignLive.{TasksListComponent, MapComponent, RidersListComponent}
  alias BikeBrigade.Delivery
  alias BikeBrigade.Delivery.{Campaign, Task, CampaignRider}
  alias BikeBrigade.Riders.Rider

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Delivery.subscribe()
    end

    {:ok,
     socket
     |> assign(:page, :campaigns)
     |> assign(:campaign, nil)
     |> assign(:resent, false)}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    id = String.to_integer(id)

    {:noreply,
     socket
     |> maybe_assign_campaign(id)
     |> apply_action(socket.assigns.live_action, params)}
  end

  @campaign_preload [
    :location,
    :scheduled_message,
    :instructions_template,
    :latest_message,
    program: [:items]
  ]

  defp maybe_assign_campaign(socket, id) do
    case socket.assigns.campaign do
      %Campaign{id: ^id} ->
        # no need to assign campaign, we already have it
        socket

      _ ->
        campaign = Delivery.get_campaign!(id, preload: @campaign_preload)

        socket
        |> assign(:page_title, name(campaign))
        |> assign_campaign(campaign)
        |> assign(:selected_task, nil)
        |> assign(:selected_rider, nil)
        |> assign(:tasks_query, %{assignment: "all"})
        |> assign(:riders_query, %{capacity: "all"})
    end
  end

  defp assign_campaign(socket, campaign) do
    {riders, tasks} = Delivery.campaign_riders_and_tasks(campaign)

    riders =
      for r <- riders, into: %{} do
        {r.id, r}
      end

    tasks =
      for t <- tasks, into: %{} do
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
    |> assign(:page_title, "New Task")
    |> assign(:form_task, %Task{})
  end

  defp apply_action(socket, :edit_task, %{"task_id" => task_id}) do
    task = Delivery.get_task(task_id)

    socket
    |> assign(:page_title, "Edit Task")
    |> assign(:form_task, task)
  end

  defp apply_action(socket, :add_rider, _) do
    socket
    |> assign(:page_title, "Add Rider")
  end

  defp apply_action(socket, :bulk_message, _) do
    socket
    |> assign(:page_title, "Message Riders for Campaign")
  end

  defp apply_action(socket, _, _), do: socket

  @impl true
  def handle_event("select_task", %{"id" => id}, socket) do
    selected_task = socket.assigns.selected_task

    socket =
      case selected_task do
        # Unselect if selected
        %{id: ^id} ->
          assign(socket, selected_task: nil)

        _ ->
          assign(socket, selected_task: get_task(socket, id))
          |> push_event("select-task", %{id: id})
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
        "filter_tasks",
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
        "filter_riders",
        %{"capacity" => capacity},
        socket
      ) do
    riders_query = Map.put(socket.assigns.riders_query, :capacity, capacity)

    {:noreply, socket |> assign(:riders_query, riders_query)}
  end

  @impl true
  def handle_event("select_rider", %{"id" => id}, socket) do
    selected_rider = socket.assigns.selected_rider

    socket =
      case selected_rider do
        # Unselect if selected
        %{id: ^id} ->
          assign(socket, selected_rider: nil)

        _ ->
          assign(socket, selected_rider: get_rider(socket, id))
          |> push_event("select_rider", %{id: id})
      end

    {:noreply, assign(socket, :resent, false)}
  end

  @impl true
  def handle_event("assign_task", %{"task_id" => task_id, "rider_id" => rider_id}, socket) do
    {:ok, _task} =
      get_task(socket, task_id)
      |> Delivery.update_task(%{assigned_rider_id: rider_id})

    {:noreply, socket}
  end

  @impl true
  def handle_event("unassign_task", %{"task_id" => task_id}, socket) do
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
  def handle_event("resend-message", %{"rider_id" => rider_id}, socket) do
    rider = get_rider(socket, rider_id)

    Delivery.send_campaign_message(socket.assigns.campaign, rider)

    {:noreply,
     socket
     |> assign(:resent, true)}
  end

  @impl Phoenix.LiveView
  def handle_event("remove-rider", %{"rider_id" => rider_id}, socket) do
    rider = get_rider(socket, rider_id)

    Delivery.remove_rider_from_campaign(socket.assigns.campaign, rider)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("delete-task", %{"task-id" => task_id}, socket) do
    task = get_task(socket, task_id)
    Delivery.delete_task(task)

    {:noreply, socket}
  end

  defmacrop belongs_to_campaign?(campaign, task) do
    quote do
      unquote(task).campaign_id == unquote(campaign).id
    end
  end

  @impl Phoenix.LiveView
  def handle_info({:campaign_updated, %Campaign{id: campaign_id}}, socket)
      when campaign_id == socket.assigns.campaign.id do
    campaign = Delivery.get_campaign(campaign_id, preload: @campaign_preload)

    {:noreply,
     socket
     |> assign_campaign(campaign)}
  end

  @impl Phoenix.LiveView
  def handle_info({:task_updated, updated_task}, socket)
      when belongs_to_campaign?(socket.assigns.campaign, updated_task) do
    %{campaign: campaign, selected_task: selected_task} = socket.assigns

    # TODO this should be as helper in the delivery.ex context?
    updated_task =
      updated_task
      |> BikeBrigade.Repo.preload(task_items: [:item])

    selected_task = replace_if_updated(selected_task, updated_task)

    # TODO this will call `Delivery.campaign_riders_and_tasks` on every change

    {:noreply,
     socket
     |> assign_campaign(campaign)
     |> assign(:selected_task, selected_task)}
  end

  @impl Phoenix.LiveView
  def handle_info({:task_deleted, %Task{id: deleted_id} = deleted_task}, socket)
      when belongs_to_campaign?(socket.assigns.campaign, deleted_task) do
    %{campaign: campaign, selected_task: selected_task} = socket.assigns

    selected_task =
      case selected_task do
        nil -> nil
        %Task{id: ^deleted_id} -> nil
        _ -> selected_task
      end

    # TODO this will call `Delivery.campaign_riders_and_tasks` on every change

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
      selected_rider =
        case selected_rider do
          nil -> nil
          %Rider{id: ^deleted_rider_id} -> nil
          _ -> selected_rider
        end

      # TODO this will call `Delivery.campaign_riders_and_tasks` on every change

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
