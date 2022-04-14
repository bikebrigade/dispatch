defmodule BikeBrigadeWeb.SmsMessageLive.Index do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigadeWeb.SmsMessageLive.ConversationComponent
  alias BikeBrigade.Presence
  alias BikeBrigade.Messaging
  alias BikeBrigade.Riders
  alias BikeBrigade.Delivery

  import BikeBrigadeWeb.MessagingHelpers
  import BikeBrigadeWeb.CampaignHelpers, only: [request_type: 1]

  @impl true
  def mount(_params, _session, socket) do
    conversations = Messaging.list_sms_conversations(limit: 10)
    # Show the most recent conversation if we have any
    rider =
      case conversations do
        [{rider, _} | _] -> rider
        _ -> nil
      end

    socket =
      socket
      |> assign(:page_title, "Messages")
      |> assign(:page, :messages)
      |> assign(:presence, [])
      |> assign(:others_present, [])
      |> assign(:conversations, conversations)
      |> assign_rider(rider)

    socket =
      if connected?(socket) do
        topic = "messaging_presence"

        Messaging.subscribe()

        # TODO why endpoint and not BikeBrigade.PubSub
        BikeBrigadeWeb.Endpoint.subscribe(topic)
        Delivery.subscribe()

        Presence.track(
          self(),
          topic,
          socket.assigns.current_user.id,
          %{}
        )

        presence = Presence.list(topic)

        send(self(), :load_all_conversations)

        assign(socket, :presence, presence)
        |> assign(:others_present, others_present(socket, presence))
      else
        socket
      end

    {:ok, socket, temporary_assigns: [conversations: []]}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> apply_action(socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event(
        "change-delivery-status",
        %{"task-id" => task_id, "delivery-status" => delivery_status},
        socket
      ) do
    # TODO some error handling
    task = Delivery.get_task(task_id)

    # TODO: fix the changeset to not set assigned_rider
    Delivery.update_task(task, %{delivery_status: delivery_status})

    {:noreply, socket}
  end

  @impl true
  def handle_event("update-notes", %{"task-id" => task_id, "value" => notes}, socket) do
    # TODO some error handling
    task = Delivery.get_task(task_id)

    Delivery.update_task(task, %{delivery_status_notes: notes})

    {:noreply, socket}
  end

  @impl true
  def handle_info(:load_all_conversations, socket) do
    socket =
      socket
      |> assign(:conversations, Messaging.list_sms_conversations())

    {:noreply, socket}
  end

  @impl true
  def handle_info({:message_created, message}, socket) do
    if message.rider_id == socket.assigns.selected_rider.id do
      send_update(ConversationComponent, id: message.rider_id, conversation: [message])
    end

    rider = Riders.get_rider(message.rider_id)

    {:noreply,
     socket
     |> assign(:conversations, [{rider, message}])
     |> push_event("new_message", %{"riderId" => rider.id})}
  end

  @impl true
  def handle_info({:message_updated, message}, socket) do
    if message.rider_id == socket.assigns.selected_rider.id do
      send_update(ConversationComponent, id: message.rider_id, conversation: [message])
    end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:task_updated, task}, %{assigns: %{selected_rider: selected_rider}} = socket) do
    if task.assigned_rider_id == selected_rider.id do
      latest_campaign_tasks = Delivery.latest_campaign_tasks(selected_rider)
      {:noreply, assign(socket, latest_campaign_tasks: latest_campaign_tasks)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(
        %{event: "presence_diff", payload: %{joins: joins, leaves: leaves}},
        socket
      ) do
    presence =
      Map.merge(socket.assigns.presence, joins)
      |> Map.drop(Map.keys(leaves))

    {:noreply,
     socket
     |> assign(:presence, presence)
     |> assign(:others_present, others_present(socket, presence))}
  end

  @impl true
  @doc "silently ignore new kinds of messages"
  def handle_info(_, socket), do: {:noreply, socket}

  defp apply_action(socket, :new, _params) do
    socket
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    rider = Riders.get_rider!(id)
    assign_rider(socket, rider)
  end

  defp apply_action(socket, :tasks, %{"id" => id}) do
    rider = Riders.get_rider!(id)
    assign_rider(socket, rider)
  end

  defp apply_action(socket, :index, _params) do
    socket
  end

  defp assign_rider(socket, nil) do
    socket
    |> assign(:selected_rider, nil)
    |> assign(:latest_campaign_tasks, [])
  end

  defp assign_rider(socket, rider) do
    latest_campaign_tasks = Delivery.latest_campaign_tasks(rider)

    socket
    |> assign(:selected_rider, rider)
    |> assign(:latest_campaign_tasks, latest_campaign_tasks)
    |> push_event("select_rider", %{"id" => rider.id})
  end

  defp details_buffer(campaign) do
    for task <- campaign.tasks do
      "Name: #{task.dropoff_name}\nPhone: #{task.dropoff_phone}\nType: #{request_type(task)}\nAddress: #{task.dropoff_location}\nNotes: #{task.rider_notes}"
    end
    |> Enum.join("\n\n")
    |> inspect()
  end

  defp others_present(socket, presence) do
    %{current_user: current_user} = socket.assigns

    for {_, %{user: u}} <- presence, u.id != current_user.id do
      u
    end
  end
end
