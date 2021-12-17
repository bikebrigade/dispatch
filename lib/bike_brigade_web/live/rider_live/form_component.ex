defmodule BikeBrigadeWeb.RiderLive.FormComponent do
  use BikeBrigadeWeb, :live_component

  alias BikeBrigade.Location
  alias BikeBrigade.Riders
  alias BikeBrigade.Riders.Rider
  alias BikeBrigadeWeb.Components.LocationForm

  defmodule RiderForm do
    use BikeBrigade.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :name, :string
      field :pronouns, :string
      field :email, :string
      field :phone, BikeBrigade.EctoPhoneNumber.Canadian
      field :availability, :map
      field :capacity, Rider.CapacityEnum
      field :max_distance, :integer
      field :last_safety_check, :date
      embeds_one :flags, Rider.Flags, on_replace: :update
      embeds_one :location_struct, Location, on_replace: :update
    end

    def changeset(form, attrs \\ %{}) do
      form
      |> cast(attrs, [
        :name,
        :pronouns,
        :email,
        :phone,
        :capacity,
        :max_distance,
        :last_safety_check
      ])
      |> cast_embed(:flags)
      |> cast_embed(:location_struct, with: &Location.geocoding_changeset/2)
      |> validate_required([
        :name,
        :email,
        :phone,
        :availability,
        :capacity,
        :max_distance,
        :location_struct
      ])
    end

    def from_rider(%Rider{} = rider) do
      map = Map.from_struct(rider)
      struct(__MODULE__, map)
    end

    def to_params(%__MODULE__{} = form) do
      Map.from_struct(form)
      |> Map.update!(:location_struct, &Map.from_struct/1)
      |> Map.update!(:flags, &Map.from_struct/1)
    end

    def update_form(%__MODULE__{} = form, params) do
      form
      |> changeset(params)
      #|> IO.inspect()
      |> apply_action(:save)
    end
  end

  @impl true
  def update(%{rider: rider} = assigns, socket) do
    rider = rider |> Repo.preload(:tags)
    form = RiderForm.from_rider(rider)
    changeset = RiderForm.changeset(form)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:rider, rider)
     |> assign(:form, form)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"rider_form" => rider_form_params}, socket) do
    case RiderForm.update_form(socket.assigns.form, rider_form_params) do
      {:ok, form} ->
        {:noreply,
         socket
         |> assign(:form, form)
         |> assign(:changeset, RiderForm.changeset(form))}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("save", %{"rider_form" => rider_form_params}, socket) do
    save_rider(socket, socket.assigns.action, rider_form_params)
  end

  defp save_rider(socket, :edit, rider_form_params) do
    with {:ok, form} <-
           RiderForm.update_form(socket.assigns.form, rider_form_params),
         params = RiderForm.to_params(form),
         {:ok, _rider} <-
           Riders.update_rider(socket.assigns.rider, params) do
      {:noreply,
       socket
       |> put_flash(:info, "Rider updated successfully")
       |> push_redirect(to: socket.assigns.return_to)}
    else
      _ -> {:noreply, assign(socket, :changeset, socket.assigns.changeset)}
    end
  end

  defp save_rider(socket, :new, rider_params) do
    case Riders.create_rider(rider_params) do
      {:ok, _rider} ->
        {:noreply,
         socket
         |> put_flash(:info, "Rider created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
