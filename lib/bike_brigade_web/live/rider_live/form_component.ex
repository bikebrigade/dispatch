defmodule BikeBrigadeWeb.RiderLive.FormComponent do
  use BikeBrigadeWeb, :live_component

  alias BikeBrigade.Repo
  alias BikeBrigade.Locations.Location
  alias BikeBrigade.Accounts
  alias BikeBrigade.Riders
  alias BikeBrigade.Riders.Rider
  alias BikeBrigadeWeb.Components.LiveLocation

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
      field :internal_notes, :string
      field :text_based_itinerary, :boolean
      field :tags, {:array, :string}
      field :anonymous_in_leaderboard, :boolean

      embeds_one :flags, Rider.Flags, on_replace: :update
      belongs_to :location, Location, on_replace: :update
    end

    @shared_permitted_keys [
      :name,
      :pronouns,
      :email,
      :phone,
      :capacity,
      :max_distance,
      :anonymous_in_leaderboard
    ]

    @doc """
    Dispatchers can edit a rider in their entirety; a rider can edit a
    subsection of their profile. We handle both cases here by matching on what
    the action is for the page.
    """
    def changeset(form, action, attrs \\ %{}) do
      changeset_impl(form, action, attrs)
      |> cast_assoc(:location, with: &Location.geocoding_changeset/2)
      |> validate_required([
        :name,
        :email,
        :phone,
        :capacity,
        :max_distance,
        :location
      ])
    end

    # `:edit` - the dispatcher is editing the rider
    def changeset_impl(form, :edit, attrs) do
      form
      |> cast(
        attrs,
        @shared_permitted_keys ++
          [:last_safety_check, :internal_notes, :text_based_itinerary, :tags]
      )
      |> cast_embed(:flags)
    end

    # `:edit_profile` - the rider is editing their own profile.
    def changeset_impl(form, :edit_profile, attrs) do
      form |> cast(attrs, @shared_permitted_keys ++ [:tags])
    end

    def from_rider(%Rider{} = rider) do
      map =
        rider
        |> Repo.preload(:tags)
        |> Map.from_struct()
        |> Map.update!(:tags, fn tags -> Enum.map(tags, & &1.name) end)

      struct(__MODULE__, map)
    end

    def to_params(%__MODULE__{} = form) do
      Map.from_struct(form)
      |> Map.update!(:location, &Map.from_struct/1)
      |> Map.update!(:flags, &Map.from_struct/1)
    end

    def update_form(%__MODULE__{} = form, action, params) do
      form
      |> changeset(action, params)
      |> apply_action(:save)
    end
  end

  @impl true
  def update(%{rider: rider} = assigns, socket) do
    rider = rider |> Repo.preload(:tags)
    form = RiderForm.from_rider(rider)
    changeset = RiderForm.changeset(form, assigns.action)

    # Get names of restricted tags for the TagsComponent
    restricted_tag_names =
      rider.tags
      |> Enum.filter(& &1.restricted)
      |> Enum.map(& &1.name)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:rider, rider)
     |> assign(:form, form)
     |> assign(:changeset, changeset)
     |> assign(:restricted_tag_names, restricted_tag_names)}
  end

  @impl true
  def handle_event("validate", %{"rider_form" => rider_form_params}, socket) do
    case RiderForm.update_form(socket.assigns.form, socket.assigns.action, rider_form_params) do
      {:ok, form} ->
        {:noreply,
         socket
         |> assign(:form, form)
         |> assign(:changeset, RiderForm.changeset(form, socket.assigns.action))}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("save", %{"rider_form" => rider_form_params}, socket) do
    save_rider(socket, socket.assigns.action, rider_form_params)
  end

  def handle_event("enable_login", _params, socket) do
    socket =
      case Accounts.create_user_for_rider(socket.assigns.rider) do
        {:ok, _user} ->
          socket
          |> put_flash(:info, "Login enabled")
          |> push_navigate(to: socket.assigns.navigate)

        {:error, _error} ->
          socket
          |> put_flash(:error, "Unable to enable login")
      end

    {:noreply, socket}
  end

  defp save_rider(socket, :edit, rider_form_params) do
    save_rider_edit_impl(socket, rider_form_params)
  end

  defp save_rider(socket, :edit_profile, rider_form_params) do
    save_rider_edit_impl(socket, rider_form_params)
  end

  defp save_rider_edit_impl(socket, rider_form_params) do
    rider_form_params = Map.merge(%{"tags" => []}, rider_form_params)

    with {:ok, form} <-
           RiderForm.update_form(socket.assigns.form, socket.assigns.action, rider_form_params),
         params = RiderForm.to_params(form),
         {:ok, _rider} <-
           Riders.update_rider_with_tags(socket.assigns.rider, params, params[:tags]) do
      {:noreply,
       socket
       |> put_flash(:info, "Rider updated successfully")
       |> push_navigate(to: socket.assigns.navigate)}
    else
      _ -> {:noreply, assign(socket, :changeset, socket.assigns.changeset)}
    end
  end
end
