defmodule BikeBrigadeWeb.AlertsLive.FormComponent do
  use BikeBrigadeWeb, :live_component

  alias BikeBrigade.Messaging
  alias BikeBrigade.MediaStorage
  alias BikeBrigade.Riders
  alias BikeBrigade.SmsService

  @impl true
  def mount(socket) do
    banner = Messaging.new_banner()
    changeset = Messaging.banner_changeset(banner, %{})

    socket =
      socket
      |> assign(:banner, banner)
      |> assign(:changeset, changeset)
      |> assign(:banners, [])

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    IO.inspect(assigns.banner, label: "@@@@@@@@@@@!!!!!!!!!!!")
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

    handle_save(socket, socket.assigns.action, banner_payload)

    # TODO: leaving off, need to include the user_id of who created it.
    # handle_save(socket, socket.assigns)

    {:noreply, socket |> push_redirect(to: ~p"/alerts")}
  end

  defp handle_save(socket, :edit, banner_form_params) do
    IO.inspect(banner_form_params, label: "about to edit >>>>>>>>>>.")
    Messaging.update_banner(socket.assigns.banner, banner_form_params)
   
  end

  defp handle_save(socket, :new, banner_form_params) do
    Messaging.create_banner(%Messaging.Banner{}, banner_form_params)
    
  end
end
