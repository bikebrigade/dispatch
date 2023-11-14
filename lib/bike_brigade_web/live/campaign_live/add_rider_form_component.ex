defmodule BikeBrigadeWeb.CampaignLive.AddRiderFormComponent do
  use BikeBrigadeWeb, :live_component

  alias BikeBrigade.Delivery
  alias BikeBrigade.Delivery.CampaignRider
  alias BikeBrigade.Riders

  @impl Phoenix.LiveComponent
  def mount(socket) do
    changeset = Delivery.CampaignRider.changeset(%CampaignRider{})

    {:ok, assign(socket, :changeset, changeset)}
  end

  # Update in the case that no rider is currently passed in.
  def update(%{rider: rider = %{rider_id: nil}} = assigns, socket) do
    changeset = Delivery.CampaignRider.changeset(rider)

    {:ok,
     socket
     |> assign(assigns)
     # we pass nil here if we are Adding a new rider
     |> assign(:selected_rider, nil)
     |> assign(:changeset, changeset)}
  end

  # Update where a rider get fetched and pre-populates the rider search
  def update(%{rider: rider} = assigns, socket) do
    changeset = Delivery.CampaignRider.changeset(rider)
    selected_rider = Riders.get_rider!(rider.rider_id)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:selected_rider, selected_rider)
     |> assign(:changeset, changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"campaign_rider" => cr_params}, socket) do
    changeset =
      socket.assigns.rider
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
         |> push_redirect(to: ~p"/campaigns/#{campaign}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("save", %{"campaign_rider" => cr_params}, socket) do
    handle_save_impl(cr_params, socket, socket.assigns.action)
  end

  def handle_save_impl(params, socket, :add_rider) do
    campaign = socket.assigns.campaign
    attrs = Map.put(params, "campaign_id", campaign.id)

    case Delivery.create_campaign_rider(attrs) do
      {:ok, _cr} ->
        {:noreply,
         socket
         |> push_redirect(to: ~p"/campaigns/#{campaign}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_save_impl(params, socket, :edit_rider) do
    case Delivery.update_campaign_rider(socket.assigns.rider, params) do
      {:ok, _rider} ->
        {:noreply,
         socket
         |> put_flash(:info, "rider update successfully")
         |> push_navigate(to: socket.assigns.navigate)}

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
