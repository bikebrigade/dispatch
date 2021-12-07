defmodule BikeBrigadeWeb.CampaignLive.FormComponent do
  use BikeBrigadeWeb, :live_component

  alias BikeBrigade.LocalizedDateTime

  alias BikeBrigade.Delivery
  alias BikeBrigade.Delivery.Campaign
  alias BikeBrigade.Importers.GSheetsImporter

  alias BikeBrigadeWeb.Components.LocationFormComponent

  defmodule CampaignForm do
    use BikeBrigade.Schema
    import Ecto.Changeset

    defmodule DeliveryDateTimeForm do
      use BikeBrigade.Schema
      import Ecto.Changeset

      @primary_key false
      embedded_schema do
        field :delivery_date, :date
        field :start_time, :time
        field :end_time, :time
      end

      def changeset(form, attrs \\ %{}) do
        form
        |> cast(attrs, [:delivery_date, :start_time, :end_time])
      end

      def from_date_times(nil, _), do: %__MODULE__{}
      def from_date_times(_, nil), do: %__MODULE__{}

      def from_date_times(delivery_start, delivery_end) do
        %__MODULE__{
          delivery_date: LocalizedDateTime.to_date(delivery_start),
          start_time: LocalizedDateTime.to_time(delivery_start),
          end_time: LocalizedDateTime.to_time(delivery_end)
        }
      end

      def to_date_times(%__MODULE__{
            delivery_date: delivery_date,
            start_time: start_time,
            end_time: end_time
          }) do
        {LocalizedDateTime.new!(delivery_date, start_time),
         LocalizedDateTime.new!(delivery_date, end_time)}
      end
    end

    @primary_key false
    embedded_schema do
      embeds_one :campaign, Campaign, on_replace: :update
      embeds_one :date_time_form, DeliveryDateTimeForm, on_replace: :update
    end

    def changeset(campaign_form, attrs \\ %{}) do
      campaign_form
      |> cast(attrs, [])
      |> cast_embed(:campaign)
      |> cast_embed(:date_time_form)
    end

    def from_campaign(campaign) do
      date_time_form =
        DeliveryDateTimeForm.from_date_times(campaign.delivery_start, campaign.delivery_end)

      %__MODULE__{campaign: campaign, date_time_form: date_time_form}
    end
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
    changeset =
      socket.assigns.campaign_form
      |> CampaignForm.changeset(campaign_form_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"campaign_form" => campaign_form_params}, socket) do
    save_campaign(socket, socket.assigns.action, campaign_form_params)
  end

  defp save_campaign(socket, :edit, %{
         "campaign" => campaign_params,
         "date_time_form" => date_time_form_params
       }) do
    with {:ok, delivery_date_time_form} <-
           CampaignForm.DeliveryDateTimeForm.changeset(
             %CampaignForm.DeliveryDateTimeForm{},
             date_time_form_params
           )
           |> Ecto.Changeset.apply_action(:validate),
         {delivery_start, delivery_end} <-
           CampaignForm.DeliveryDateTimeForm.to_date_times(delivery_date_time_form),
         campaign_params <-
           campaign_params
           |> Map.put("delivery_start", delivery_start)
           |> Map.put("delivery_end", delivery_end) do
      case Delivery.update_campaign(socket.assigns.campaign, campaign_params) do
        {:ok, _campaign} ->
          {:noreply,
           socket
           |> put_flash(:info, "Campaign updated successfully")
           |> push_redirect(to: socket.assigns.return_to)}

        {:error, %Ecto.Changeset{} = _changeset} ->
          # TODO this skips error handling
          # assign(socket, changeset: changeset)}
          {:noreply, socket}
      end
    end
  end

  defp save_campaign(socket, :new, %{
         "campaign" => campaign_params,
         "date_time_form" => date_time_form_params
       }) do
    # {:ok, office_addr} = BikeBrigade.Geocoder.lookup("926 College St Toronto Canada")

    # campaign_params =
    #   Map.merge(
    #     campaign_params,
    #     %{
    #       "pickup_address" => "926 College St",
    #       "pickup_postal" => "M6H 1A4",
    #       "pickup_city" => "Toronto",
    #       "pickup_country" => "Canada",
    #       "pickup_location" => %Geo.Point{
    #         coordinates: {office_addr.lon, office_addr.lat}
    #       }
    #     }
    #   )

    with {:ok, delivery_date_time_form} <-
           CampaignForm.DeliveryDateTimeForm.changeset(
             %CampaignForm.DeliveryDateTimeForm{},
             date_time_form_params
           )
           |> Ecto.Changeset.apply_action(:validate),
         {delivery_start, delivery_end} <-
           CampaignForm.DeliveryDateTimeForm.to_date_times(delivery_date_time_form),
         campaign_params <-
           campaign_params
           |> Map.put("delivery_start", delivery_start)
           |> Map.put("delivery_end", delivery_end) do
      case Delivery.create_campaign(campaign_params) do
        {:ok, campaign} ->
          if campaign_params["task_spreadsheet_url"] &&
               campaign_params["task_spreadsheet_url"] != "" do
            GSheetsImporter.import_tasks_from_spreadsheet(
              campaign,
              campaign_params["task_spreadsheet_url"]
            )
          end

          if campaign_params["rider_spreadsheet_url"] &&
               campaign_params["rider_spreadsheet_url"] != "" do
            GSheetsImporter.import_riders_from_spreadsheet(
              campaign,
              campaign_params["rider_spreadsheet_url"]
            )
          end

          {:noreply,
           socket
           |> put_flash(:info, "Campaign created successfully")
           |> push_redirect(to: socket.assigns.return_to)}

        {:error, %Ecto.Changeset{} = _changeset} ->
          # TODO this skips error handling
          # assign(socket, changeset: changeset)}
          {:noreply, socket}
      end
    end
  end

  defp program_options do
    programs =
      for p <- Delivery.list_programs() do
        {p.name, p.id}
      end

    [{"", nil} | programs]
  end
end
