defmodule BikeBrigadeWeb.SmsMessageLive.Index do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigadeWeb.Components.ConversationComponent
  alias BikeBrigade.{Presence, Messaging, Delivery, Riders, Riders.RiderSearch}

  import BikeBrigadeWeb.Components.SMSMessageListComponent
  import BikeBrigadeWeb.CampaignHelpers, only: [request_type: 1]

  alias BikeBrigadeWeb.CampaignHelpers
  defdelegate campaign_name(campaign), to: CampaignHelpers, as: :name
  defdelegate pickup_window(campaign, rider), to: CampaignHelpers

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
      |> stream(:conversations, conversations,
        dom_id: fn {rider, _} -> "conversation-list-item:#{rider.id}" end
      )
      |> assign(:rider_search_value, "")
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

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> apply_action(socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("search_riders", %{"search" => ""}, socket) do
    {:noreply,
     socket
     |> assign(:rider_search_value, "")
     |> push_event("conversation_list:clear_search", %{})}
  end

  @impl true
  def handle_event("search_riders", %{"search" => search}, socket) do
    filter = %RiderSearch.Filter{type: :name, search: search}

    {_rs, results} =
      RiderSearch.new(filters: [filter], limit: 1000)
      |> RiderSearch.fetch()

    rider_ids = for r <- results.page, do: r.id

    {:noreply,
     socket
     |> assign(:rider_search_value, search)
     |> push_event("conversation_list:only_show", %{"ids" => rider_ids})}
  end

  @impl true
  def handle_event(
        "change_delivery_status",
        %{"task_id" => task_id, "delivery_status" => delivery_status},
        socket
      ) do
    # TODO some error handling
    task = Delivery.get_task(task_id)

    # TODO: fix the changeset to not set assigned_rider
    Delivery.update_task(task, %{delivery_status: delivery_status})

    {:noreply, socket}
  end

  @impl true
  def handle_event("update_notes", %{"task_id" => task_id, "value" => notes}, socket) do
    # TODO some error handling
    task = Delivery.get_task(task_id)

    Delivery.update_task(task, %{delivery_status_notes: notes})

    {:noreply, socket}
  end

  @impl true
  def handle_info(:load_all_conversations, socket) do
    conversations = Messaging.list_sms_conversations()
    socket = stream(socket, :conversations, conversations, reset: true)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:message_created, message}, socket) do
    if message.rider_id == socket.assigns.selected_rider.id do
      send_update(ConversationComponent, id: message.rider_id, conversation: [message])
    end

    socket =
      if rider = Riders.get_rider(message.rider_id) do
        socket
        |> stream_insert(:conversations, {rider, message}, at: 0)
        |> push_event("conversation_list:new_message", %{"riderId" => rider.id})
      else
        socket
      end

    {:noreply, socket}
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
    |> assign(:page_title, "Message Riders")
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
    |> push_event("conversation_list:select_rider", %{"id" => rider.id})
  end

  defp details_buffer(campaign) do
    for task <- campaign.tasks do
      "Name: #{task.dropoff_name}\nPhone: #{task.dropoff_phone}\nType: #{request_type(task)}\nAddress: #{task.dropoff_location}\nNotes: #{task.delivery_instructions}"
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

  attr :others_present, :list, required: true

  defp currently_viewing(assigns) do
    ~H"""
    <div
      :if={!Enum.empty?(@others_present)}
      class="fixed top-0 right-0 z-10 flex-col items-end hidden mt-2 mr-2 sm:flex"
    >
      <div
        id="currently-viewing"
        class="hidden w-64 bg-white border border-gray-200 shadow sm:rounded-lg"
      >
        <div class="px-2 py-3 bg-white border-b border-gray-200 sm:rounded-t-lg">
          <div class="absolute top-0 right-0 pt-4 pr-4 sm:block">
            <button
              phx-click={JS.hide(to: "#currently-viewing") |> JS.show(to: "#currently-viewing-close")}
              type="button"
              class="block text-gray-400 bg-white rounded-md hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              <span class="sr-only">Close</span>
              <Heroicons.x_mark solid class="w-6 h-6" />
            </button>
          </div>
          <div class="flex flex-wrap items-center">
            <h3 class="text-lg font-medium leading-6 text-gray-900">
              {Enum.count(@others_present)} Currently Viewing
            </h3>
          </div>
        </div>
        <ul class="px-2 py-3">
          <%= for user <- @others_present
          do %>
            <li>{user.name}</li>
          <% end %>
        </ul>
      </div>

      <div id="currently-viewing-close">
        <.button
          phx-click={JS.hide(to: "#currently-viewing-close") |> JS.show(to: "#currently-viewing")}
          type="button"
          color={:white}
          rounded={:full}
        >
          <Heroicons.eye solid class="w-5 h-5" />
          <span class="ml-1 text-sm font-semibold">{Enum.count(@others_present)}</span>
        </.button>
      </div>
    </div>
    """
  end
end
