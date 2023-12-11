defmodule BikeBrigadeWeb.CampaignSignupLive.SignupRiderFormComponent do
  use BikeBrigadeWeb, :live_component

  alias BikeBrigade.Delivery
  alias BikeBrigade.Delivery.CampaignRider

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
  def handle_event("rider_signup", %{"campaign_rider" => cr_params}, socket) do
    %{rider_id: rider_id, task: task, campaign: campaign} = socket.assigns
    attrs = Map.merge(cr_params, %{"campaign_id" => campaign.id, "rider_id" => rider_id})

    case Delivery.create_campaign_rider(attrs) do
      {:ok, _cr} ->
        {:ok, _task} = Delivery.update_task(task, %{assigned_rider_id: rider_id})
        {:noreply, socket |> push_redirect(to: ~p"/campaigns/signup/#{campaign}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("rider_signup", _params, socket) do
    {:noreply,
     socket
     |> put_flash(:error, "rider is required")}
  end

end
