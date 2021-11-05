defmodule BikeBrigadeWeb.CampaignLive.MessagingFormComponent do
  use BikeBrigadeWeb, :live_component
  alias BikeBrigadeWeb.CampaignHelpers

  alias BikeBrigade.Messaging
  alias BikeBrigade.Delivery

  import BikeBrigade.Utils, only: [humanized_task_count: 1]
  import BikeBrigadeWeb.DeliveryHelpers

  @impl true
  def update(%{campaign: campaign} = assigns, socket) do
    ## reload the task collection cuz we're not updating the message on the main view
    #campaign = Delivery.get_campaign(campaign.id)

    changeset =
      if campaign.instructions_template do
        Delivery.change_campaign(campaign)
      else
        Delivery.change_campaign(campaign, %{instructions_template: %{body: ""}})
      end

    selected_rider = campaign.riders |> List.first()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:selected_rider, selected_rider)
     |> assign(:selected_rider_index, 0)
     #|> assign(:campaign, campaign)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"sms_message" => sms_message_params}, socket) do
    changeset =
      socket.assigns.sms_message
      |> Messaging.send_sms_message_changeset(sms_message_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("select-rider", %{"selected_rider_index" => selected_rider_index}, socket) do
    %{
      campaign: campaign,
      selected_rider_index: old_selected_rider_index
    } = socket.assigns

    socket =
      case Integer.parse(selected_rider_index) do
        # didn't select a new rider, do nothing
        {^old_selected_rider_index, ""} ->
          socket

        # selected a new rider
        {new_selected_rider_index, ""} ->
          socket
          |> assign(:selected_rider_index, new_selected_rider_index)
          |> assign(:selected_rider, Enum.at(campaign.riders, new_selected_rider_index))

        # parameter isn't valid integer
        _ ->
          socket
      end

    {:noreply, socket}
  end

  def handle_event("select-rider", _, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("preview", %{"campaign" => campaign_params}, socket) do
    %{campaign: campaign} = socket.assigns
    IO.inspect campaign_params

    changeset =
      campaign
      |> Delivery.change_campaign(campaign_params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(changeset: changeset)}
  end

  def handle_event("save", %{"campaign" => campaign_params}, socket) do
    case Delivery.update_campaign(socket.assigns.campaign, campaign_params) do
      {:ok, campaign} ->
        {:noreply, assign(socket, campaign: campaign, changeset:  Delivery.change_campaign(campaign))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("send", _params, socket) do

    # Remove schedule
    {:ok, campaign} = socket.assigns.changeset
    |> Map.put(:action, :update)
    |> Delivery.update_campaign(%{"scheduled_message" => nil})

    Delivery.send_campaign_messages(campaign)

    {:noreply,
     socket
     |> assign(campaign: campaign)
     |> put_flash(:info, "Successfully sent messages!")
     |> push_redirect(to: Routes.campaign_show_path(socket, :show, campaign))}
  end

  def handle_event("delete-schedule", _, socket) do
    case Delivery.update_campaign(socket.assigns.campaign, %{"scheduled_message" => nil}) do
      {:ok, campaign} ->
        {:noreply, assign(socket, campaign: campaign, changeset:  Delivery.change_campaign(campaign))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end


  defp directives do
    ~w(rider_name pickup_address pickup_window task_details task_count directions delivery_details_url)
  end

  defp preview(campaign, changeset, selected_rider) do
    body = Ecto.Changeset.get_field(changeset, :instructions_template).body

    if selected_rider do
      Delivery.render_campaign_message_for_rider(campaign, body, selected_rider)
    else
      "<em>Need a rider with assigned tasks to preview</em>"
    end
  end

  defp rider_selection_options(campaign, selected_rider_index) do
    options =
      for {r, i} <- Enum.with_index(campaign.riders) do
        count = Enum.count(r.assigned_tasks)
        name = "#{r.name} (#{count})"

        {name, i}
      end

    options_for_select(options, selected_rider_index)
  end
end
