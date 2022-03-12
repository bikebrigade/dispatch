defmodule BikeBrigadeWeb.CampaignLive.AddRiderFormComponent do
  use BikeBrigadeWeb, :live_component

  alias BikeBrigade.Delivery
  alias BikeBrigade.Delivery.CampaignRider
  import BikeBrigadeWeb.CampaignHelpers

  @impl Phoenix.LiveComponent
  def mount(socket) do
    changeset = Delivery.CampaignRider.changeset(%CampaignRider{})

    {:ok, assign(socket, :changeset, changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"campaign_rider" => cr_params}, socket) do
    changeset =
      %CampaignRider{}
      |> CampaignRider.changeset(cr_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("add_rider", %{"campaign_rider" => cr_params}, socket) do
    campaign = socket.assigns.campaign
    attrs = Map.put(cr_params, "campaign_id", campaign.id)
    case Delivery.create_campaign_rider(attrs) do
      {:ok, _cr} ->
        {:noreply,
         socket
         |> push_redirect(to: Routes.campaign_show_path(socket, :show, campaign))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event(
        "add_rider",
        _params,
        socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "rider is required")}
  end
end
