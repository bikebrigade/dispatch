defmodule BikeBrigadeWeb.AlertsLive.FormComponent do
  use BikeBrigadeWeb, :live_component

  alias BikeBrigade.Messaging
  alias BikeBrigade.MediaStorage
  alias BikeBrigade.Riders
  alias BikeBrigade.SmsService

  @impl true
  def mount(socket) do
    IO.inspect(socket, label: "!!!!!!!!!!!!!@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
    banner = Messaging.new_banner()
    changeset = Messaging.banner_changeset(banner, %{})

    socket =
      socket
      |> allow_upload(:media, accept: ~w(.gif .png .jpg .jpeg), max_entries: 10)
      |> assign(:banner, banner)
      |> assign(:changeset, changeset)
      |> assign(:banners, [])

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    {:ok, socket |> assign(assigns)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"banner" => banner_params}, socket) do
    changeset =
      Messaging.banner_changeset(socket.assigns.banner, banner_params)

    {:noreply, socket |> assign(changeset: changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("submit", %{"banner" => banner_params}, socket) do
    {:ok, dateOn} = Date.from_iso8601(banner_params["turn_on_at_date"])
    {:ok, dateOff} = Date.from_iso8601(banner_params["turn_off_at_date"])
    {:ok, timeOn} = Time.from_iso8601("#{banner_params["turn_on_at_time"]}:00")
    {:ok, timeOff} = Time.from_iso8601("#{banner_params["turn_off_at_time"]}:00")

    date_time_on = BikeBrigade.LocalizedDateTime.new!(dateOn, timeOn)
    date_time_off = BikeBrigade.LocalizedDateTime.new!(dateOff, timeOff)

    banner_payload = %{
      "turn_off_at" => date_time_off,
      "turn_on_at" => date_time_on,
      "message" => banner_params["message"],
      "created_by_user_id" => socket.assigns.current_user.id
    }

    # TODO: leaving off, need to include the user_id of who created it.
    x = Messaging.create_banner(%Messaging.Banner{}, banner_payload)

    {:noreply, socket |> push_redirect(to: ~p"/alerts")}
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
