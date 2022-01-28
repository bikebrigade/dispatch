defmodule BikeBrigadeWeb.SmsMessageLive.FormComponent do
  use BikeBrigadeWeb, :live_component

  alias BikeBrigade.Messaging
  alias BikeBrigade.Riders
  alias BikeBrigade.SmsService

  @impl true
  def mount(socket) do
    changeset =
      Messaging.new_sms_message()
      |> Messaging.send_sms_message_changeset()

    {:ok,
     socket
     |> assign(:changeset, changeset)
     |> assign(:initial_riders, [])
     |> assign_confirm_send_warning()}
  end

  def assign_confirm_send_warning(socket) do
    assign(socket, :confirm_send, SmsService.sending_confirmation_message())
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "send",
        %{"sms_message" => params, "rider_ids" => [rider_id | _] = rider_ids},
        socket
      ) do
    riders = Riders.get_riders(rider_ids)

    for rider <- riders do
      # TODO handle errors
      sms_message = Messaging.new_sms_message(rider, sent_by: socket.assigns.current_user)
      Messaging.send_sms_message(sms_message, params)
    end

    {:noreply,
     socket
     |> push_redirect(to: Routes.sms_message_index_path(socket, :show, rider_id))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("send", %{"sms_message" => params}, socket) do
    # Missing the rider id means we didn't pick a rider
    changeset =
      Messaging.new_sms_message()
      |> Messaging.send_sms_message_changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end
end
