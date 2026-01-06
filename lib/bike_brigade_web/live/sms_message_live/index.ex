defmodule BikeBrigadeWeb.SmsMessageLive.Index do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigadeWeb.Components.ConversationComponent
  alias BikeBrigade.{Presence, Messaging, Delivery, Riders, Riders.RiderSearch}
  alias BikeBrigade.Messaging.MessageSearch

  import BikeBrigadeWeb.Components.SMSMessageListComponent
  import BikeBrigadeWeb.CampaignHelpers, only: [request_type: 1]

  alias BikeBrigadeWeb.CampaignHelpers
  defdelegate campaign_name(campaign), to: CampaignHelpers, as: :name
  defdelegate pickup_window(campaign, rider), to: CampaignHelpers

  defmodule Suggestions do
    @moduledoc """
    Provides search suggestions for program filtering.
    """
    alias BikeBrigade.Messaging.MessageSearch.Filter
    alias BikeBrigade.Delivery

    defstruct programs: []

    @type t :: %__MODULE__{
            programs: list(Filter.t())
          }

    @spec suggest(t(), String.t()) :: t()
    def suggest(_suggestions, ""), do: %__MODULE__{}

    def suggest(_suggestions, search) do
      case String.split(search, ":", parts: 2) do
        ["program", program] ->
          programs =
            Delivery.list_programs(search: program)
            |> Enum.map(&%Filter{type: :program, search: &1.name, id: &1.id})

          %__MODULE__{programs: programs}

        [search] ->
          programs =
            if String.length(search) < 3 ||
                 String.starts_with?("program", String.downcase(search)) do
              Delivery.list_programs()
            else
              Delivery.list_programs(search: search)
            end
            |> Enum.map(&%Filter{type: :program, search: &1.name, id: &1.id})

          %__MODULE__{programs: programs}

        [_, _] ->
          # unknown facet
          %__MODULE__{}
      end
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Messages")
      |> assign(:page, :messages)
      |> assign(:presence, [])
      |> assign(:others_present, [])
      |> assign(:message_search, MessageSearch.new())
      |> assign(:suggestions, %Suggestions{})
      |> assign(:show_suggestions, false)
      |> assign(:program_search, "")
      |> assign(:rider_search_value, "")
      |> assign(:selected_rider, nil)
      |> assign(:latest_campaign_tasks, [])

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
        # Load initial conversations for initial render (SSR)
        conversations = Messaging.list_sms_conversations(limit: 10)

        socket
        |> stream(:conversations, conversations,
          dom_id: fn {rider, _} -> "conversation-list-item:#{rider.id}" end
        )
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
  def handle_event("suggest_program", %{"value" => search}, socket) do
    {:noreply,
     socket
     |> update(:suggestions, &Suggestions.suggest(&1, search))
     |> assign(:program_search, search)
     |> assign(:show_suggestions, true)}
  end

  @impl true
  def handle_event("filter", params, socket) do
    new_filter =
      case params do
        %{"type" => type, "search" => search, "id" => id} when is_integer(id) ->
          %MessageSearch.Filter{
            type: String.to_atom(type),
            search: search,
            id: id
          }

        %{"type" => type, "search" => search, "id" => id} when is_binary(id) ->
          %MessageSearch.Filter{
            type: String.to_atom(type),
            search: search,
            id: String.to_integer(id)
          }

        %{"value" => value} when is_binary(value) and value != "" ->
          parse_filter(value)

        _ ->
          nil
      end

    new_filters =
      if new_filter do
        # Don't add duplicate filters
        if Enum.any?(socket.assigns.message_search.filters, fn f ->
             f.type == new_filter.type && f.id == new_filter.id
           end) do
          socket.assigns.message_search.filters
        else
          socket.assigns.message_search.filters ++ [new_filter]
        end
      else
        socket.assigns.message_search.filters
      end

    # Serialize filters to URL params
    filter_params =
      new_filters
      |> Enum.map(fn %MessageSearch.Filter{type: type, search: search} ->
        "#{type}:#{search}"
      end)

    {:noreply,
     socket
     |> update(:message_search, &MessageSearch.filter(&1, new_filters))
     |> clear_program_search()
     |> push_patch(to: ~p"/messages?#{%{filters: filter_params}}")}
  end

  @impl true
  def handle_event("clear_program_search", _params, socket) do
    {:noreply, clear_program_search(socket)}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> update(:message_search, &MessageSearch.filter(&1, []))
     |> push_patch(to: ~p"/messages")}
  end

  @impl true
  def handle_event("remove_filter", %{"index" => i}, socket) do
    filters = List.delete_at(socket.assigns.message_search.filters, i)

    filter_params =
      filters
      |> Enum.map(fn %MessageSearch.Filter{type: type, search: search} ->
        "#{type}:#{search}"
      end)

    path =
      if filter_params == [] do
        ~p"/messages"
      else
        ~p"/messages?#{%{filters: filter_params}}"
      end

    {:noreply,
     socket
     |> update(:message_search, &MessageSearch.filter(&1, filters))
     |> push_patch(to: path)}
  end

  defp clear_program_search(socket) do
    socket
    |> assign(:program_search, "")
    |> assign(:suggestions, %Suggestions{})
    |> assign(:show_suggestions, false)
  end

  defp get_program_ids(filters) do
    filters
    |> Enum.filter(&(&1.type == :program))
    |> Enum.map(& &1.id)
  end

  @impl true
  def handle_info(:load_all_conversations, socket) do
    {:noreply, load_conversations(socket)}
  end

  @impl true
  def handle_info({:message_created, message}, socket) do
    if message.rider_id == socket.assigns.selected_rider.id do
      send_update(ConversationComponent, id: message.rider_id, conversation: [message])
    end

    # Check if message's inferred program matches filtered programs
    should_show? =
      case get_program_ids(socket.assigns.message_search.filters) do
        [] ->
          # No filters, show all messages
          true

        program_ids ->
          # Infer program from message timestamp and rider's tasks
          inferred_program_id = Messaging.infer_program_for_message(message)
          inferred_program_id && inferred_program_id in program_ids
      end

    socket =
      if should_show? do
        case Riders.get_rider(message.rider_id) do
          nil ->
            socket

          rider ->
            socket
            |> stream_insert(:conversations, {rider, message}, at: 0)
            |> push_event("conversation_list:new_message", %{"riderId" => rider.id})
        end
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

  defp apply_action(socket, :index, params) do
    filters =
      Map.get(params, "filters", [])
      |> Enum.map(&parse_filter/1)
      |> Enum.reject(&is_nil/1)

    socket
    |> assign(:message_search, MessageSearch.new(filters: filters))
    |> load_conversations()
  end

  defp apply_action(socket, :new, params) do
    socket
    |> apply_action(:index, params)
    |> assign(:page_title, "Message Riders")
  end

  defp apply_action(socket, :show, %{"id" => id} = params) do
    rider = Riders.get_rider!(id)

    socket
    |> apply_action(:index, params)
    |> assign_rider(rider)
  end

  defp apply_action(socket, :tasks, %{"id" => id} = params) do
    rider = Riders.get_rider!(id)

    socket
    |> apply_action(:index, params)
    |> assign_rider(rider)
  end

  defp parse_filter("program:" <> search) do
    if program = Delivery.get_program_by_name(search) do
      %MessageSearch.Filter{type: :program, search: search, id: program.id}
    end
  end

  defp parse_filter(_), do: nil

  defp load_conversations(socket) do
    program_ids =
      socket.assigns.message_search.filters
      |> Enum.filter(&(&1.type == :program))
      |> Enum.map(& &1.id)

    opts =
      if program_ids != [] do
        [program_ids: program_ids]
      else
        []
      end

    conversations = Messaging.list_sms_conversations(opts)

    # If there are conversations and no rider is selected, select the first one
    socket =
      case {conversations, socket.assigns[:selected_rider]} do
        {[{rider, _} | _], nil} -> assign_rider(socket, rider)
        _ -> socket
      end

    socket
    |> stream(:conversations, conversations,
      reset: true,
      dom_id: fn {rider, _} -> "conversation-list-item:#{rider.id}" end
    )
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

  # Program filter UI components

  attr :filters, :list, required: true

  defp filter_list(assigns) do
    ~H"""
    <%= if @filters != [] do %>
      <div class="flex flex-wrap space-x-0.5">
        <%= for {%MessageSearch.Filter{type: type, search: search}, i} <- Enum.with_index(@filters) do %>
          <div class="my-0.5 inline-flex items-center px-2.5 py-1.5 rounded-md text-md font-medium bg-indigo-100 text-indigo-800">
            <span class="text-700 mr-0.5 font-base">{type}:</span>{search}
            <Heroicons.x_circle
              mini
              class="w-5 h-5 ml-1 cursor-pointer"
              phx-click={JS.push("remove_filter", value: %{index: i})}
            />
          </div>
        <% end %>
      </div>
    <% end %>
    """
  end

  attr :suggestions, :map, required: true
  attr :open, :boolean, required: true

  defp suggestion_list(assigns) do
    ~H"""
    <dialog
      id="suggestion-list"
      open={@open}
      class="absolute z-10 w-full p-2 mt-0 overflow-y-auto bg-white border rounded shadow-xl top-100 max-h-fit"
      phx-window-keydown="clear_program_search"
      phx-key="escape"
    >
      <%= if @suggestions.programs != [] do %>
        <h3 class="my-1 text-xs font-medium tracking-wider text-left text-gray-500 uppercase">
          Program
        </h3>
        <div class="flex flex-col my-2">
          <%= for program <- @suggestions.programs do %>
            <.suggestion filter={program} />
          <% end %>
        </div>
      <% end %>
    </dialog>
    """
  end

  attr :filter, :map, required: true

  defp suggestion(assigns) do
    ~H"""
    <div id={"program-#{@filter.id}"} class="px-1 py-0.5 rounded-md focus-within:bg-gray-100">
      <button
        type="button"
        phx-click={add_filter(@filter)}
        class="block ml-1 transition duration-150 ease-in-out w-fit hover:bg-gray-50 focus:outline-none focus:bg-gray-50"
        tabindex="1"
      >
        <p class="px-2.5 py-1.5 rounded-md text-md font-medium bg-indigo-100 text-indigo-800">
          <span class="mr-0.5 text-sm">program:</span>{@filter.search}
        </p>
      </button>
    </div>
    """
  end

  defp add_filter(%MessageSearch.Filter{} = filter) do
    JS.push("filter", value: %{type: filter.type, search: filter.search, id: filter.id})
  end
end
