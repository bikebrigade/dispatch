defmodule BikeBrigadeWeb.CampaignLive.MessagingFormComponent do
  use BikeBrigadeWeb, :live_component
  alias BikeBrigadeWeb.CampaignHelpers

  alias BikeBrigade.LocalizedDateTime

  alias BikeBrigade.Messaging
  alias BikeBrigade.Delivery

  import BikeBrigade.Utils, only: [humanized_task_count: 1]
  import BikeBrigadeWeb.DeliveryHelpers

  @impl true
  def update(%{campaign: campaign, riders: riders} = assigns, socket) do
    ## reload the task collection cuz we're not updating the message on the main view
    # campaign = Delivery.get_campaign(campaign.id)

    # TODO this is a smell, and frankly is happening because instructions template shouldn't be its own table :(
    {changeset, message_length} =
      case campaign do
        %{instructions_template: %{body: body}} when not is_nil(body) ->
          {Delivery.change_campaign(campaign), String.length(body)}

        _ ->
          {Delivery.change_campaign(campaign, %{instructions_template: %{body: ""}}), 0}
      end

    selected_rider =
      riders
      |> Map.values()
      |> List.first()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:selected_rider, selected_rider)
     |> assign(:changeset, changeset)
     |> assign(:message_length, message_length)}
  end

  # TODO is this dead code?
  @impl true
  def handle_event("validate", %{"sms_message" => sms_message_params}, socket) do
    changeset =
      socket.assigns.sms_message
      |> Messaging.send_sms_message_changeset(sms_message_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("select_rider", %{"selected_rider_id" => rider_id}, socket) do
    rider_id = String.to_integer(rider_id)

    {:noreply,
     socket
     |> assign(:selected_rider, Map.get(socket.assigns.riders, rider_id))}
  end

  def handle_event("select_rider", _, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("preview", %{"campaign" => campaign_params}, socket) do
    %{campaign: campaign} = socket.assigns
    send_at = campaign_params["scheduled_message"]["send_at"]

    campaign_params =
      if send_at != "" do
        localized_send_at =
          NaiveDateTime.from_iso8601!("#{send_at}:00")
          |> LocalizedDateTime.localize()

        put_in(
          campaign_params["scheduled_message"]["send_at"],
          localized_send_at
        )
      else
        campaign_params
      end

    changeset =
      campaign
      |> Delivery.change_campaign(campaign_params)
      |> Map.put(:action, :validate)

    message_length = String.length(campaign_params["instructions_template"]["body"])

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> assign(:message_length, message_length)}
  end

  def handle_event("save", %{"campaign" => campaign_params}, socket) do
    send_at = campaign_params["scheduled_message"]["send_at"]

    campaign_params =
      if send_at != "" do
        localized_send_at =
          NaiveDateTime.from_iso8601!("#{send_at}:00")
          |> LocalizedDateTime.localize()

        put_in(
          campaign_params["scheduled_message"]["send_at"],
          localized_send_at
        )
      else
        campaign_params
      end

    case Delivery.update_campaign(socket.assigns.campaign, campaign_params) do
      {:ok, campaign} ->
        {:noreply,
         assign(socket, campaign: campaign, changeset: Delivery.change_campaign(campaign))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("send", _params, socket) do
    # Remove schedule
    {:ok, campaign} =
      socket.assigns.changeset
      |> Map.put(:action, :update)
      |> Delivery.update_campaign(%{"scheduled_message" => nil})

    Delivery.send_campaign_messages(campaign)

    {:noreply,
     socket
     |> assign(campaign: campaign)
     |> put_flash(:info, "Successfully sent messages!")
     |> push_navigate(to: socket.assigns.navigate)}
  end

  def handle_event("delete_schedule", _, socket) do
    case Delivery.update_campaign(socket.assigns.campaign, %{"scheduled_message" => nil}) do
      {:ok, campaign} ->
        {:noreply,
         assign(socket, campaign: campaign, changeset: Delivery.change_campaign(campaign))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp preview(campaign, changeset, selected_rider) do
    body = Ecto.Changeset.get_field(changeset, :instructions_template).body

    if selected_rider do
      Delivery.render_campaign_message_for_rider(campaign, body, selected_rider)
    else
      "<em>Need a rider with assigned tasks to preview</em>"
    end
  end

  defp rider_selection_options(riders, selected_rider) do
    options =
      for {id, r} <- riders do
        count = Enum.count(r.assigned_tasks)
        name = "#{r.name} (#{count})"

        {name, id}
      end

    options_for_select(options, selected_rider && selected_rider.id)
  end

  defp message_length_indicator(assigns) do
    indicator_color =
      cond do
        assigns.length < 1200 -> "text-emerald-600"
        assigns.length <= 1400 -> "text-amber-400"
        true -> "text-red-600"
      end

    assigns = assign(assigns, :color, indicator_color)

    ~H"""
    <div class="flex text-xs font-medium text-gray-600">
      <span class={@color}><%= @length %>/1600</span>
      <.with_tooltip>
        <Heroicons.question_mark_circle solid class="w-4 h-4 ml-0.5 " />
        <:tooltip>
          <div class="w-40">
            Messages over 1600 characters in length tend to get broken up into multiple texts.
          </div>
        </:tooltip>
      </.with_tooltip>
    </div>
    """
  end

  defp show_scheduling(js \\ %JS{}) do
    js
    |> JS.show(to: ".show-if-scheduling", display: "flex")
    |> JS.hide(to: ".hide-if-scheduling")
  end

  defp hide_scheduling(js \\ %JS{}) do
    js
    |> JS.hide(to: ".show-if-scheduling")
    |> JS.show(to: ".hide-if-scheduling", display: "flex")
  end
end
