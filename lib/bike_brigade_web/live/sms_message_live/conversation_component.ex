defmodule BikeBrigadeWeb.SmsMessageLive.ConversationComponent do
  use BikeBrigadeWeb, :live_component

  import BikeBrigadeWeb.MessagingHelpers

  alias BikeBrigade.Messaging
  alias BikeBrigade.MediaStorage
  alias BikeBrigade.SmsService

  @impl Phoenix.LiveComponent
  def mount(socket) do
    socket =
      socket
      |> allow_upload(:media, accept: ~w(.gif .png .jpg .jpeg), max_entries: 10)
      |> assign_confirm_send_warning()

    {:ok, socket, temporary_assigns: [scrollback: [], conversation: []]}
  end

  def assign_confirm_send_warning(socket) do
    assign(socket, :confirm_send, SmsService.sending_confirmation_message())
  end

  @impl Phoenix.LiveComponent
  def update(%{rider: rider} = assigns, socket) do
    conversation = Messaging.latest_messages(rider)

    earliest_timestamp =
      case conversation do
        [first | _] -> first.sent_at
        [] -> nil
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign_new_sms_message()
     |> assign(conversation: conversation)
     |> assign(earliest_timestamp: earliest_timestamp)
     |> assign(phx_update: "append")}
  end

  @impl Phoenix.LiveComponent
  def update(%{conversation: conversation} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(conversation: conversation)
     |> assign(phx_update: "append")
     |> push_event("new-message", %{})}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :media, ref)}
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
        %{"sms_message" => sms_message_params},
        socket
      ) do
    media =
      consume_uploaded_entries(socket, :media, fn %{path: path}, %{client_type: content_type} ->
        # TOOD do some guards on content type here
        MediaStorage.upload_file!(path, content_type)
      end)

    {:noreply, send_sms_message(socket, Map.put(sms_message_params, "media", media))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("load-more", _params, socket) do
    %{rider: rider, earliest_timestamp: earliest_timestamp} = socket.assigns
    conversation = Messaging.latest_messages(rider, earliest_timestamp)

    case conversation do
      [first | _] ->
        {:reply, %{},
         socket
         |> assign(:conversation, conversation)
         |> assign(:earliest_timestamp, first.sent_at)
         |> assign(:phx_update, "prepend")}

      [] ->
        {:reply, %{}, socket}
    end
  end

  defp send_sms_message(socket, params) do
    case Messaging.send_sms_message(socket.assigns.sms_message, params) do
      {:ok, _sent_sms_message} ->
        assign_new_sms_message(socket)
      {:error, %Ecto.Changeset{} = changeset} ->
        assign(socket, :changeset, changeset)
    end
  end

  defp assign_new_sms_message(socket) do
    sms_message = Messaging.new_sms_message(socket.assigns.rider, sent_by: socket.assigns.current_user)
    changeset = Messaging.send_sms_message_changeset(sms_message)

    socket
    |> assign(changeset: changeset)
    |> assign(sms_message: sms_message)
  end

  def error_to_string(:too_large), do: "Too large"
  def error_to_string(:too_many_files), do: "You have selected too many files"
  def error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
end
