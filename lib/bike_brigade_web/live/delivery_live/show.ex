defmodule BikeBrigadeWeb.DeliveryLive.Show do
  use BikeBrigadeWeb, {:live_view, layout: :public}

  alias BikeBrigade.Delivery
  alias BikeBrigadeWeb.CampaignHelpers
  import BikeBrigadeWeb.DeliveryHelpers
  import BikeBrigade.Utils, only: [humanized_task_count: 1]

  alias BikeBrigadeWeb.DeliveryExpiredError

  @check_expiry Mix.env() == :prod

  @impl Phoenix.LiveView
  def mount(%{"token" => token}, _session, socket) do
    %{campaign: campaign, rider: rider, pickup_window: pickup_window} =
      Delivery.get_campaign_rider!(token)

    # TODO this is hacky but will go away

    rider = %{rider | pickup_window: pickup_window}

    campaign_date = CampaignHelpers.campaign_date(campaign)

    if @check_expiry && Date.diff(Date.utc_today(), campaign.delivery_start) > 5 do
      raise DeliveryExpiredError
    end

    # Subscribe to delivery topic to receive real-time task updates
    if connected?(socket) do
      Delivery.subscribe()
    end

    {:ok,
     socket
     |> assign(:campaign, campaign)
     |> assign(:campaign_date, campaign_date)
     |> assign(:page_title, "#{campaign_name(campaign)} - #{campaign_date}")
     |> assign(:rider, rider)
     |> assign(:active_note_task_id, nil)
     |> assign(:note_text, "")}
  end

  @impl Phoenix.LiveView
  def handle_event("toggle_note_form", %{"task-id" => task_id}, socket) do
    task_id = String.to_integer(task_id)

    active_task_id =
      if socket.assigns.active_note_task_id == task_id do
        nil
      else
        task_id
      end

    {:noreply,
     socket
     |> assign(:active_note_task_id, active_task_id)
     |> assign(:note_text, "")}
  end

  @impl Phoenix.LiveView
  def handle_event("update_note", %{"note" => note}, socket) do
    {:noreply, assign(socket, :note_text, note)}
  end

  @impl Phoenix.LiveView
  def handle_event("submit_note", %{"task_id" => task_id, "note" => note}, socket) do
    task_id = String.to_integer(task_id)

    case Delivery.create_delivery_note(%{
           note: note,
           rider_id: socket.assigns.rider.id,
           task_id: task_id
         }) do
      {:ok, _delivery_note} ->
        {:noreply,
         socket
         |> assign(:active_note_task_id, nil)
         |> assign(:note_text, "")
         |> put_flash(:info, "Note submitted")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to submit note")}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("mark_complete", %{"task-id" => task_id}, socket) do
    task_id = String.to_integer(task_id)

    case Delivery.mark_task_complete_by_rider(task_id, socket.assigns.rider.id) do
      {:ok, _updated_task} ->
        {:noreply, put_flash(socket, :info, "Delivery marked as completed")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, reason)}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("mark_all_complete", _params, socket) do
    rider_id = socket.assigns.rider.id
    campaign_id = socket.assigns.campaign.id

    task_ids =
      socket.assigns.rider.assigned_tasks
      |> Enum.filter(fn task -> task.delivery_status in [:pending, :picked_up] end)
      |> Enum.map(& &1.id)

    case Delivery.mark_all_tasks_complete_by_rider(rider_id, campaign_id, task_ids) do
      {:ok, %{count: count}} ->
        {:noreply, put_flash(socket, :info, "#{count} deliveries marked as completed")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, reason)}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({:task_updated, task}, socket) do
    {:noreply, update_task(socket, task)}
  end

  def handle_info({:tasks_batch_completed, tasks}, socket) do
    updated_assigned_tasks =
      Enum.map(socket.assigns.rider.assigned_tasks, fn task ->
        Enum.find_value(tasks, task, fn updated_task ->
          if updated_task.id == task.id do
            updated_task
          end
        end)
      end)

    {:noreply,
     assign(socket, :rider, %{socket.assigns.rider | assigned_tasks: updated_assigned_tasks})}
  end

  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  defp update_task(socket, task) do
    cond do
      task.assigned_rider_id == socket.assigns.rider.id ->
        updated_tasks =
          Enum.map(
            socket.assigns.rider.assigned_tasks,
            fn
              %{id: id} = _original_task when id == task.id -> task
              original_task -> original_task
            end
          )

        assign(socket, :rider, %{socket.assigns.rider | assigned_tasks: updated_tasks})

      true ->
        socket
    end
  end
end
