defmodule BikeBrigadeWeb.BannerLive.FormComponent do
  use BikeBrigadeWeb, :live_component
  use Ecto.Schema
  import Ecto.Changeset

  alias BikeBrigade.Messaging
  alias BikeBrigade.Messaging.Banner
  alias BikeBrigade.LocalizedDateTime

  embedded_schema do
    field :message, :string
    field :turn_on_date, :date
    field :turn_on_time, :time
    field :turn_off_date, :date
    field :turn_off_time, :time
    field :enabled, :boolean
    field :created_by_id, :id
  end

  def changeset(form, attrs \\ %{}) do
    form
    |> cast(attrs, [
      :message,
      :turn_on_date,
      :turn_on_time,
      :turn_off_date,
      :turn_off_time,
      :enabled,
      :created_by_id
    ])
    |> validate_required([:message, :turn_on_date, :turn_on_time, :turn_off_date, :turn_off_time])
  end

  def from_banner(%Banner{} = banner) do
    # TODO: leaving off - banner is empty with nil values, so it fails.

    %__MODULE__{
      message: banner.message,
      turn_on_date: LocalizedDateTime.to_date(banner.turn_on_at),
      turn_on_time: LocalizedDateTime.to_time(banner.turn_on_at),
      turn_off_date: LocalizedDateTime.to_date(banner.turn_off_at),
      turn_off_time: LocalizedDateTime.to_time(banner.turn_off_at),
      enabled: banner.enabled,
      created_by_id: banner.created_by_id
    }
  end

  def from_banner(_), do: %__MODULE__{enabled: true}

  def to_banner_params(%__MODULE__{} = banner_form) do
    %{
      message: banner_form.message,
      turn_on_at: LocalizedDateTime.new!(banner_form.turn_on_date, banner_form.turn_on_time),
      turn_off_at: LocalizedDateTime.new!(banner_form.turn_off_date, banner_form.turn_off_time),
      enabled: banner_form.enabled,
      created_by_id: banner_form.created_by_id
    }
  end

  @impl true
  def update(%{banner: banner} = assigns, socket) do
    banner_form = from_banner(banner)
    changeset = changeset(banner_form, %{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"form_component" => banner_params}, socket) do
    banner_form = from_banner(socket.assigns.banner)

    changeset =
      banner_form
      |> changeset(banner_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"form_component" => banner_params}, socket) do
    save_banner(socket, socket.assigns.action, banner_params)
  end

  defp save_banner(socket, :edit, banner_params) do
    banner_form = from_banner(socket.assigns.banner)
    changeset = changeset(banner_form, banner_params)

    if changeset.valid? do
      converted_params = changeset |> Ecto.Changeset.apply_changes() |> to_banner_params()

      case Messaging.update_banner(socket.assigns.banner, converted_params) do
        {:ok, banner} ->
          notify_parent({:saved, banner})

          {:noreply,
           socket
           |> put_flash(:info, "Banner updated successfully")
           |> push_patch(to: socket.assigns.patch)}

        {:error, %Ecto.Changeset{} = _changeset} ->
          {:noreply, assign(socket, :changeset, %{changeset | action: :insert})}
      end
    else
      {:noreply, assign(socket, :changeset, %{changeset | action: :insert})}
    end
  end

  defp save_banner(socket, :new, banner_params) do
    banner_params = Map.put(banner_params, "created_by_id", socket.assigns.current_user.id)
    banner_form = from_banner(nil)
    changeset = changeset(banner_form, banner_params)

    if changeset.valid? do
      converted_params = changeset |> Ecto.Changeset.apply_changes() |> to_banner_params()

      case Messaging.create_banner(converted_params) do
        {:ok, banner} ->
          notify_parent({:saved, banner})

          {:noreply,
           socket
           |> put_flash(:info, "Banner created successfully!")
           |> push_patch(to: socket.assigns.patch)}

        {:error, %Ecto.Changeset{} = _changeset} ->
          {:noreply,
           socket
           # HACK: this push patch is needed for the flash to work ¯\_(ツ)_/¯
           |> push_patch(to: ~p"/banners/new")
           |> put_flash(
             :error,
             "Your banner is scheduled incorrectly. Is the start time later than the stop time?"
           )}
      end
    else
      {:noreply, assign(socket, :changeset, %{changeset | action: :insert})}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
