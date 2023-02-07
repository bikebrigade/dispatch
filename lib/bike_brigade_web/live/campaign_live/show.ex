defmodule BikeBrigadeWeb.CampaignLive.Show do
  use BikeBrigadeWeb, :live_view

  import BikeBrigadeWeb.CampaignHelpers
  import BikeBrigade.Utils, only: [replace_if_updated: 2]
  alias BikeBrigadeWeb.CampaignLive.{TasksListComponent, RidersListComponent}
  alias BikeBrigade.Delivery
  alias BikeBrigade.Delivery.{Campaign, Task, CampaignRider}
  alias BikeBrigade.Riders.Rider

  @unselected_task_color "#c3ddfd"
  @selected_task_color "#5145cd"
  @selected_rider_color "#5850ec"
  @unselected_rider_color "#4a5568"

  # Below is for when we add lines to the map
  # indigo-200
  # @pickup_line_color "#c7d2fe"
  # indigo-400
  # @dropoff_line_color "#818cf8"

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
    previously_selected_task = socket.assigns.selected_task
    task = get_task(socket, id)

    socket =
      if selected?(previously_selected_task, task) do
        # If we already selected the task, we will unselect it
        socket
        |> assign(selected_task: nil)
        |> push_map_events(previously_selected_task)
      else
        socket
        |> assign(selected_task: task)
        |> push_event("tasks_list:select_task", %{id: id})
        |> push_map_events(previously_selected_task)
        |> push_map_events(task)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("auto_assign", _, socket) do
    BikeBrigade.Delivery.hacky_assign(socket.assigns.campaign)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "search_tasks",
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
        "search_riders",
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
    previously_selected_rider = socket.assigns.selected_rider

    rider = get_rider(socket, id)

    socket =
      if selected?(previously_selected_rider, rider) do
        # If we already selected the rider, we will unselect it
        socket
        |> assign(selected_rider: nil)
        |> push_map_events(previously_selected_rider)
      else
        socket
        |> assign(selected_rider: rider)
        |> push_event("riders_list:select_rider", %{id: id})
        |> push_map_events(previously_selected_rider)
        |> push_map_events(rider)
      end

    {:noreply, socket}
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
        "change_delivery_status",
        %{"task_id" => task_id, "delivery_status" => delivery_status},
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
  def handle_event("resend_message", %{"rider_id" => rider_id}, socket) do
    rider = get_rider(socket, rider_id)

    Delivery.send_campaign_message(socket.assigns.campaign, rider)

    {:noreply,
     socket
     |> assign(:resent, true)}
  end

  @impl Phoenix.LiveView
  def handle_event("remove_rider", %{"rider_id" => rider_id}, socket) do
    rider = get_rider(socket, rider_id)

    Delivery.remove_rider_from_campaign(socket.assigns.campaign, rider)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("delete_task", %{"task_id" => task_id}, socket) do
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
     |> assign(:selected_task, selected_task)
     |> push_map_events(updated_task)}
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
     |> assign(:selected_task, selected_task)
     |> push_event("leaflet:remove_layers", %{layers: [%{id: "task-#{deleted_id}"}]})}
  end

  @impl true
  def handle_info(
        {:campaign_rider_created, %CampaignRider{campaign_id: campaign_id, rider_id: rider_id}},
        socket
      ) do
    %{campaign: campaign} = socket.assigns

    if campaign_id == campaign.id do
      # TODO this will call `Delivery.campaign_riders_and_tasks` on every change
      socket = assign_campaign(socket, campaign)
      rider = Map.get(socket.assigns.riders, rider_id)

      {:noreply,
       socket
       |> push_event("leaflet:add_layers", %{layers: [rider_marker(rider)]})}
    else
      {:noreply, socket}
    end
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
       |> assign(:selected_rider, selected_rider)
       |> push_event("leaflet:remove_layers", %{layers: [%{id: "rider-#{deleted_rider_id}"}]})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  @doc "silently ignore new kinds of messages"
  def handle_info(_, socket), do: {:noreply, socket}

  attr :campaign, Campaign, required: true
  attr :riders, :list, required: true
  attr :tasks, :list, required: true

  defp campaign_map(assigns) do
    campaign_marker = %{
      id: "campaign",
      type: :marker,
      data: %{
        lat: lat(assigns.campaign.location),
        lng: lng(assigns.campaign.location),
        icon: "warehouse",
        color: "#1c64f2",
        tooltip: "Pickup Location"
      }
    }

    rider_markers =
      for {_id, rider} <- assigns.riders do
        rider_marker(rider)
      end

    task_markers =
      for {id,
           %Task{
             dropoff_name: dropoff_name,
             dropoff_location: location,
             assigned_rider_id: assigned_rider_id
           }} <- assigns.tasks do
        %{
          id: "task-#{id}",
          type: :marker,
          data: %{
            lat: lat(location),
            lng: lng(location),
            icon: if(assigned_rider_id, do: "circle", else: "cross"),
            color: @unselected_task_color,
            clickEvent: "select_task",
            clickValue: %{id: id},
            tooltip: dropoff_name
          }
        }
      end

    assigns = assign(assigns, :initial_layers, [campaign_marker | rider_markers ++ task_markers])

    ~H"""
    <.map id="campaign-map" coords={@campaign.location.coords} initial_layers={@initial_layers} />
    """
  end

  defp push_map_events(socket, nil) do
    socket
  end

  defp push_map_events(socket, %Task{id: id, assigned_rider_id: assigned_rider_id} = task) do
    color =
      if selected?(socket.assigns.selected_task, task),
        do: @selected_task_color,
        else: @unselected_task_color

    socket
    |> push_event("leaflet:update_layer", %{
      id: "task-#{id}",
      type: :marker,
      data: %{color: color, icon: if(assigned_rider_id, do: "circle", else: "cross")}
    })
  end

  defp push_map_events(socket, %Rider{id: id} = rider) do
    color =
      if selected?(socket.assigns.selected_rider, rider),
        do: @selected_rider_color,
        else: @unselected_rider_color

    socket
    |> push_event("leaflet:update_layer", %{
      id: "rider-#{id}",
      type: :marker,
      data: %{color: color}
    })
  end

  defp rider_marker(%Rider{id: id, name: name, location: location}) do
    %{
      id: "rider-#{id}",
      type: :marker,
      data: %{
        lat: lat(location),
        lng: lng(location),
        icon: "bicycle",
        color: @unselected_rider_color,
        clickEvent: "select_rider",
        clickValue: %{id: id},
        tooltip: name
      }
    }
  end

  defp has_scheduled_message?(campaign) do
    case campaign do
      %{scheduled_message: %{send_at: send_at}} when not is_nil(send_at) -> true
      _ -> false
    end
  end

  defp has_latest_message?(campaign) do
    case campaign do
      %{latest_message: %{sent_at: sent_at}} when not is_nil(sent_at) -> true
      _ -> false
    end
  end
end
