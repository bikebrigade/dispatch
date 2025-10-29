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
end
