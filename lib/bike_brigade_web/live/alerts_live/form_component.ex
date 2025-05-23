defmodule BikeBrigadeWeb.AlertsLive.FormComponent do
  use BikeBrigadeWeb, :live_component

  alias BikeBrigade.Messaging
  alias BikeBrigade.MediaStorage
  alias BikeBrigade.Riders
  alias BikeBrigade.SmsService
  alias BikeBrigade.Messaging.Banner

  defmodule BannerForm do
    use BikeBrigade.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :turn_on_at_date, :date
      field :turn_on_at_time, :time
      field :turn_off_at_date, :date
      field :turn_off_at_time, :time
      field :message, :string

      # belongs_to :user, User
    end

    def changeset(form, attrs \\ %{}) do
      form
      |> cast(attrs, [
        :turn_on_at_date, 
        :turn_on_at_time, 
        :turn_off_at_date,
        :turn_off_at_time,
        :message
      ])
      |> validate_required([:turn_on_at_date, :turn_on_at_time, :turn_off_at_date, :turn_off_at_time, :message])
    end

    def from_banner(%Banner{} = banner) do
      %__MODULE__{

        turn_on_at_date: LocalizedDateTime.to_date(banner.turn_on_at),
        turn_on_at_time: LocalizedDateTime.to_time(banner.turn_on_at),
        turn_off_at_date: LocalizedDateTime.to_date(banner.turn_off_at),
        turn_off_at_time: LocalizedDateTime.to_time(banner.turn_off_at),
        message: banner.message
      }
    end

    def to_banner_params(%__MODULE__{} = banner_form) do
      %{
        message: banner_form.message,
        turn_on_at: LocalizedDateTime.new!(banner_form.turn_on_at_date, banner_form.turn_on_at_time),
        turn_off_at: LocalizedDateTime.new!(banner_form.turn_on_at_date, banner_form.turn_on_at_time),
        created_by_user: 1 # < TODO: get this in there.
      }
    end

    def update(%__MODULE__{} = campaign_form, params) do
      campaign_form
      |> changeset(params)
      |> apply_action(:save)
    end
  end

  



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
