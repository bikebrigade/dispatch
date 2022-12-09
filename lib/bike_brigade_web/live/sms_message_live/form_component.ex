defmodule BikeBrigadeWeb.SmsMessageLive.FormComponent do
  use BikeBrigadeWeb, :live_component

  alias BikeBrigade.Messaging
  alias BikeBrigade.MediaStorage
  alias BikeBrigade.Riders
  alias BikeBrigade.SmsService

  @impl true
  def mount(socket) do
    sms_message = Messaging.new_sms_message()
    changeset = Messaging.send_sms_message_changeset(sms_message)

    socket =
      socket
      |> allow_upload(:media, accept: ~w(.gif .png .jpg .jpeg), max_entries: 10)
      |> assign_confirm_send_warning()
      |> assign(:sms_message, sms_message)
      |> assign(:changeset, changeset)
      |> assign(:initial_riders, [])

    {:ok, socket}
  end

  def assign_confirm_send_warning(socket) do
    assign(socket, :confirm_send, SmsService.sending_confirmation_message())
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"sms_message" => sms_message_params}, socket) do
    changeset =
      Messaging.send_sms_message_changeset(socket.assigns.sms_message, sms_message_params)

    {:noreply, socket |> assign(changeset: changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "send",
        %{"sms_message" => sms_message_params, "rider_ids" => [rider_id | _] = rider_ids},
        socket
      ) do
    media =
      consume_uploaded_entries(socket, :media, fn %{path: path}, %{client_type: content_type} ->
        # TODO do some guards on content type here
        {:ok, MediaStorage.upload_file!(path, content_type)}
      end)

    sms_message_params = Map.put(sms_message_params, "media", media)

    riders = Riders.get_riders(rider_ids)

    for rider <- riders do
      # TODO handle errors
      sms_message = Messaging.new_sms_message(rider, sent_by: socket.assigns.current_user)
      Messaging.send_sms_message(sms_message, sms_message_params)
    end

    {:noreply,
     socket
     |> push_redirect(to: ~p"/messages/#{rider_id}")}
  end

  @impl Phoenix.LiveComponent
  def handle_event("send", %{"sms_message" => sms_message_params}, socket) do
    # Missing the rider id means we didn't pick a rider
    changeset =
      Messaging.new_sms_message()
      |> Messaging.send_sms_message_changeset(sms_message_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :media, ref)}
  end

  def error_to_string(:too_large), do: "Too large"
  def error_to_string(:too_many_files), do: "You have selected too many files"
  def error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
end
