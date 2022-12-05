defmodule BikeBrigadeWeb.OpportunityLive.FormComponent do
  use BikeBrigadeWeb, :live_component

  alias BikeBrigade.Locations.Location
  alias BikeBrigade.Delivery
  alias BikeBrigade.Delivery.Program
  alias BikeBrigade.LocalizedDateTime

  alias BikeBrigadeWeb.Components.LiveLocation

  # TODO: DRY this with CampaignForm
  defmodule OpportunityForm do
    use BikeBrigade.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field(:program_id, :id)
      field(:delivery_date, :date)
      field(:start_time, :time)
      field(:end_time, :time)
      field(:signup_link, :string)
      field(:published, :boolean, default: false)
      field(:hide_address, :boolean, default: false)

      belongs_to :location, Location, on_replace: :update
    end

    def changeset(form, attrs \\ %{}) do
      form
      |> cast(attrs, [
        :program_id,
        :delivery_date,
        :start_time,
        :end_time,
        :signup_link,
        :published,
        :hide_address
      ])
      |> cast_assoc(:location, with: &Location.geocoding_changeset/2)
      |> validate_required([
        :program_id,
        :delivery_date,
        :start_time,
        :end_time,
        :signup_link,
        :published,
        :location
      ])
    end

    def from_opportunity(opportunity) do
      map =
        opportunity
        |> Map.from_struct()
        |> Map.merge(%{
          delivery_date:
            opportunity.delivery_start && LocalizedDateTime.to_date(opportunity.delivery_start),
          start_time:
            opportunity.delivery_start && LocalizedDateTime.to_time!(opportunity.delivery_start),
          end_time:
            opportunity.delivery_end && LocalizedDateTime.to_time!(opportunity.delivery_end)
        })

      struct(%__MODULE__{}, map)
    end

    def to_opportunity_params(form, attrs \\ %{}) do
      case changeset(form, attrs) |> apply_action(:validate) do
        {:ok, struct} ->
          %__MODULE__{delivery_date: delivery_date, start_time: start_time, end_time: end_time} =
            struct

          params =
            struct
            |> Map.from_struct()
            |> Map.update(:location, %{}, &Map.from_struct/1)
            |> Map.put(:delivery_start, LocalizedDateTime.new!(delivery_date, start_time))
            |> Map.put(:delivery_end, LocalizedDateTime.new!(delivery_date, end_time))

          {:ok, params}

        other ->
          other
      end
    end

    def update(%__MODULE__{} = opportunity_form, params) do
      opportunity_form
      |> changeset(params)
      |> apply_action(:save)
    end
  end

  # TODO: DRY this with campaigns

  @impl Phoenix.LiveComponent
  def mount(socket) do
    programs = for p <- BikeBrigade.Repo.all(Program), do: {p.name, p.id}

    {:ok,
     socket
     |> assign(:program_options, [{"", nil} | programs])}
  end

  @impl Phoenix.LiveComponent
  def update(%{opportunity: opportunity} = assigns, socket) do
    opportunity = BikeBrigade.Repo.preload(opportunity, :location)

    form = OpportunityForm.from_opportunity(opportunity)
    changeset = OpportunityForm.changeset(form)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:opportunity, opportunity)
     |> assign(:form, form)
     |> assign(:changeset, changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"opportunity_form" => opportunity_form_params}, socket) do
    case OpportunityForm.update(socket.assigns.form, opportunity_form_params) do
      {:ok, form} ->
        {:noreply,
         socket
         |> assign(:form, form)
         |> assign(:changeset, OpportunityForm.changeset(form))}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("save", %{"opportunity_form" => opportunity_form_params}, socket) do
    %{opportunity: opportunity, form: opportunity_form} = socket.assigns

    changeset = OpportunityForm.changeset(opportunity_form, opportunity_form_params)

    with {:ok, _} <- Ecto.Changeset.apply_action(changeset, :validate),
         {:ok, params} <-
           OpportunityForm.to_opportunity_params(opportunity_form, opportunity_form_params),
         {:ok, _opportunity} <- Delivery.create_or_update_opportunity(opportunity, params) do
      {:noreply,
       socket
       |> put_flash(:info, "Opportunity updated successfully")
       |> push_navigate(to: socket.assigns.navigate)}
    else
      {:error, _changeset} ->
        {:noreply, assign(socket, :changeset, changeset |> Map.put(:action, :insert))}
    end
  end
end
