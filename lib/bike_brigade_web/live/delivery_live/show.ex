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
    %{
      campaign: campaign,
      rider: rider,
      pickup_window: pickup_window,
      backup_rider: backup_rider
    } = Delivery.get_campaign_rider!(token)

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
     |> assign(:backup_rider, backup_rider)
     |> assign(:active_note_task_id, nil)
     |> assign(:note_text, "")
     |> assign(:selfie_error, nil)
     |> allow_upload(:selfie,
       accept: ~w(image/jpeg image/png image/webp image/heic image/heif),
       max_entries: 1,
       max_file_size: 20_000_000,
       auto_upload: true
     )}
  end

  @impl Phoenix.LiveView
  def handle_event("validate_selfie", _params, socket) do
    {:noreply, assign(socket, :selfie_error, nil)}
  end

  def handle_event("cancel_selfie", %{"ref" => ref}, socket) do
    {:noreply, socket |> cancel_upload(:selfie, ref) |> assign(:selfie_error, nil)}
  end

  def handle_event("upload_selfie", _params, socket) do
    {completed, in_progress} = uploaded_entries(socket, :selfie)

    if completed != [] and in_progress == [] do
      results =
        consume_uploaded_entries(socket, :selfie, fn %{path: path}, entry ->
          case BikeBrigade.Selfies.upload(
                 path,
                 entry.client_type,
                 socket.assigns.rider,
                 socket.assigns.campaign
               ) do
            {:ok, _file} -> {:ok, :uploaded}
            {:error, _reason} -> {:postpone, :failed}
          end
        end)

      if results == [:uploaded] do
        {:noreply,
         socket
         |> assign(:selfie_error, nil)
         |> put_flash(:info, "Selfie uploaded. Thank you!")}
      else
        {:noreply,
         assign(socket, :selfie_error, "Couldn't upload your selfie. Please try again.")}
      end
    else
      {:noreply,
       assign(socket, :selfie_error, "Please choose a photo and wait for it to finish loading.")}
    end
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
  def handle_event("complete_delivery", _params, socket) do
    {:ok, tasks} =
      Delivery.mark_campaign_tasks_complete_by_rider(
        socket.assigns.campaign.id,
        socket.assigns.rider.id
      )

    socket = Enum.reduce(tasks, socket, &update_task(&2, &1))
    {:noreply, put_flash(socket, :info, "Deliveries marked as completed")}
  end

  @impl Phoenix.LiveView
  def handle_info({:task_updated, task}, socket) do
    {:noreply, update_task(socket, task)}
  end

  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  defp selfie_upload_error(:too_large), do: "Photo must be smaller than 20 MB."
  defp selfie_upload_error(:too_many_files), do: "Please choose one photo."
  defp selfie_upload_error(:not_accepted), do: "Choose a JPEG, PNG, WebP, or HEIC photo."
  defp selfie_upload_error(_), do: "Couldn't load this photo. Please choose it again."

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
