defmodule BikeBrigadeWeb.CampaignLive.FormComponent do
  use BikeBrigadeWeb, :live_component

  alias BikeBrigade.LocalizedDateTime
  alias BikeBrigade.Location
  alias BikeBrigade.Delivery
  alias BikeBrigade.Delivery.{Campaign, Program}
  alias BikeBrigade.Importers.GSheetsImporter

  alias BikeBrigadeWeb.Components.LocationForm


  defmodule CampaignForm do
    use BikeBrigade.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :delivery_date, :date
      field :start_time, :time
      field :end_time, :time
      field :task_spreadsheet_url, :string
      field :rider_spreadsheet_url, :string
      field :rider_spreadsheet_layout, :string

      embeds_one :location, Location, on_replace: :update
      belongs_to :program, Program
    end

    def changeset(form, attrs \\ %{}) do
      form
      |> cast(attrs, [
        :delivery_date,
        :start_time,
        :end_time,
        :task_spreadsheet_url,
        :rider_spreadsheet_url,
        :rider_spreadsheet_layout,
        :program_id
      ])
      |> cast_embed(:location, with: &Location.geocoding_changeset/2)
      |> validate_required([:delivery_date, :start_time, :end_time, :location, :program_id])
    end

    def from_campaign(%Campaign{} = campaign) do
      %__MODULE__{
        program_id: campaign.program_id,
        delivery_date: LocalizedDateTime.to_date(campaign.delivery_start),
        start_time: LocalizedDateTime.to_time(campaign.delivery_start),
        end_time: LocalizedDateTime.to_time(campaign.delivery_end),
        location: campaign.location,
        rider_spreadsheet_layout: campaign.rider_spreadsheet_layout
      }
    end

    def to_campaign_params(%__MODULE__{} = campaign_form) do
      %{
        program_id: campaign_form.program_id,
        delivery_start:
          LocalizedDateTime.new!(campaign_form.delivery_date, campaign_form.start_time),
        delivery_end: LocalizedDateTime.new!(campaign_form.delivery_date, campaign_form.end_time),
        location: Map.from_struct(campaign_form.location),
        rider_spreadsheet_layout: campaign_form.rider_spreadsheet_layout
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
    programs = for p <- BikeBrigade.Repo.all(Program), do: {p.name, p.id}

    {:ok,
     socket
     |> assign(:program_options, [{"", nil} | programs])}
  end

  @impl true
  def update(%{campaign: campaign} = assigns, socket) do
    campaign_form = CampaignForm.from_campaign(campaign)
    changeset = CampaignForm.changeset(campaign_form)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:campaign_form, campaign_form)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"campaign_form" => campaign_form_params}, socket) do
    case CampaignForm.update(socket.assigns.campaign_form, campaign_form_params) do
      {:ok, campaign_form} ->
        {:noreply,
         assign(socket, :campaign_form, campaign_form)
         |> assign(:changeset, CampaignForm.changeset(campaign_form))}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("save", %{"campaign_form" => campaign_form_params}, socket) do
    save_campaign(socket, socket.assigns.action, campaign_form_params)
  end

  defp save_campaign(socket, :edit, campaign_form_params) do
    with {:ok, campaign_form} <-
           CampaignForm.update(socket.assigns.campaign_form, campaign_form_params),
         campaign_params = CampaignForm.to_campaign_params(campaign_form),
         {:ok, _campaign} <-
           Delivery.update_campaign(socket.assigns.campaign, campaign_params) do
      {:noreply,
       socket
       |> put_flash(:info, "Campaign updated successfully")
       |> push_redirect(to: socket.assigns.return_to)}
    else
      _ -> {:noreply, assign(socket, :changeset, socket.assigns.changeset)}
    end
  end

  defp save_campaign(socket, :new, campaign_form_params) do
    with {:ok, campaign_form} <-
           CampaignForm.update(socket.assigns.campaign_form, campaign_form_params),
         campaign_params = CampaignForm.to_campaign_params(campaign_form),
         {:ok, campaign} <-
           Delivery.create_campaign(campaign_params) do
      import_tasks_spreadsheet(campaign, campaign_form.task_spreadsheet_url)
      import_riders_spreadsheet(campaign, campaign_form.rider_spreadsheet_url)

      {:noreply,
       socket
       |> put_flash(:info, "Campaign created successfully")
       |> push_redirect(to: socket.assigns.return_to)}
    else
      {:error, changeset} -> {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp import_tasks_spreadsheet(campaign, nil), do: {:ok, campaign}

  defp import_tasks_spreadsheet(campaign, ""), do: {:ok, campaign}

  defp import_tasks_spreadsheet(campaign, task_spreadsheet_url) do
    GSheetsImporter.import_tasks_from_spreadsheet(
      campaign,
      task_spreadsheet_url
    )
  end

  defp import_riders_spreadsheet(campaign, nil), do: {:ok, campaign}

  defp import_riders_spreadsheet(campaign, ""), do: {:ok, campaign}

  defp import_riders_spreadsheet(campaign, rider_spreadsheet_url) do
    GSheetsImporter.import_riders_from_spreadsheet(
      campaign,
      rider_spreadsheet_url
    )
  end
end
