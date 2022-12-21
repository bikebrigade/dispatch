defmodule BikeBrigadeWeb.RiderLive.Index do
  use BikeBrigadeWeb, :live_view

  alias Phoenix.LiveView.JS

  alias BikeBrigade.Delivery
  alias BikeBrigade.Riders
  alias BikeBrigade.Riders.RiderSearch
  alias BikeBrigade.Riders.RiderSearch.Filter
  alias BikeBrigade.LocalizedDateTime
  alias BikeBrigade.Locations

  defmodule SortOptions do
    # This is a streamlined version of the one from leaderboard.ex
    # Deciding if we need all the ecto stuff here

    defstruct [:field, :order, offset: 0, limit: 20]

    def to_tuple(%__MODULE__{field: field, order: order, offset: offset, limit: limit}) do
      {order, field, offset, limit}
    end
  end

  defmodule Suggestions do
    @actives ~w(hour day week month year all_time never)
             |> Enum.map(&%Filter{type: :active, search: &1})
    @capacities ~w(large medium small)
                |> Enum.map(&%Filter{type: :capacity, search: &1})

    defstruct name: nil, phone: nil, tags: [], programs: [], active: [], capacity: []

    @type t :: %__MODULE__{
            name: Filter.t() | nil,
            tags: list(Filter.t()),
            programs: list(Filter.t()),
            active: list(Filter.t()),
            capacity: list(Filter.t())
          }

    @spec suggest(t(), String.t()) :: t()
    def suggest(suggestions, "") do
      %{suggestions | name: nil, tags: [], programs: [], active: [], capacity: []}
    end

    def suggest(suggestions, search) do
      case String.split(search, ":", parts: 2) do
        ["tag", tag] ->
          tags =
            Riders.search_tags(tag)
            |> Enum.map(&%Filter{type: :tag, search: &1.name})

          %__MODULE__{tags: tags}

        ["program", program] ->
          programs =
            Delivery.list_programs(search: program)
            |> Enum.map(&%Filter{type: :program, search: &1.name, id: &1.id})

          %__MODULE__{programs: programs}

        ["active", active] ->
          actives =
            @actives
            |> Enum.filter(&String.starts_with?(&1.search, active))

          %__MODULE__{active: actives}

        ["capacity", capacity] ->
          capacity =
            @capacities
            |> Enum.filter(&String.starts_with?(&1.search, capacity))

          %__MODULE__{capacity: capacity}

        [search] ->
          tags =
            if String.length(search) < 3 do
              Riders.list_tags()
            else
              Riders.search_tags(search)
            end
            |> Enum.map(& &1.name)
            |> Enum.map(&%Filter{type: :tag, search: &1})

          programs =
            if String.length(search) < 3 ||
                 String.starts_with?("program", String.downcase(search)) do
              Delivery.list_programs()
            else
              Delivery.list_programs(search: search)
            end
            |> Enum.map(&%Filter{type: :program, search: &1.name, id: &1.id})

          phone =
            if search =~ ~r/^\d+$/ do
              %Filter{type: :phone, search: search}
            end

          name = %Filter{type: :name, search: search}

          %{
            suggestions
            | name: name,
              phone: phone,
              tags: tags,
              programs: programs,
              active: @actives,
              capacity: @capacities
          }

        [_, _] ->
          # unknown facet
          %__MODULE__{}
      end
    end
  end

  @selected_color "#5850ec"
  @unselected_color "#4a5568"

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page, :riders)
     |> assign(:page_title, "Riders")
     |> assign(:selected, MapSet.new())
     |> assign(:search, "")
     |> assign(:search_results, %RiderSearch.Results{})
     |> assign(:all_locations, [])
     |> assign(:suggestions, %Suggestions{})
     |> assign(:show_suggestions, false)
     |> assign(:mode, :list)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @preloads [:tags, :latest_campaign, location: [:neighborhood]]
  @default_rider_search RiderSearch.new(preload: @preloads)

  defp apply_action(socket, :index, params) do
    filters =
      Map.get(params, "filters", [])
      |> Enum.map(&parse_filter/1)

    rider_search =
      RiderSearch.new(
        filters: filters,
        preload: @preloads
      )

    socket
    |> assign_new(:rider_search, fn -> rider_search end)
    |> fetch_results()
    |> remove_selected_riders()
  end

  defp apply_action(socket, :message, _params) do
    riders =
      socket.assigns.selected
      |> MapSet.to_list()
      |> Riders.get_riders()

    socket
    |> assign(:page_title, "Bulk Message Riders")
    |> assign_new(:rider_search, fn -> @default_rider_search end)
    |> fetch_results()
    |> assign(:initial_riders, riders)
  end

  defp apply_action(socket, :map, params) do
    socket
    |> assign(:all_locations, [])
    |> assign(:mode, :map)
    |> apply_action(:index, params)
  end

  @impl Phoenix.LiveView
  def handle_event("filter", params, socket) do
    new_filter =
      case params do
        %{"type" => type, "search" => search, "id" => id} ->
          %Filter{type: String.to_existing_atom(type), search: search, id: id}

        %{"type" => type, "search" => search} ->
          {String.to_existing_atom(type), search}

        %{"value" => value} when is_binary(value) and value != "" ->
          parse_filter(value)

        # don't add a filter
        _ ->
          nil
      end

    new_filters = if new_filter, do: [new_filter], else: []

    {:noreply,
     socket
     |> update(:rider_search, &RiderSearch.filter(&1, &1.filters ++ new_filters))
     |> fetch_results()
     |> clear_search()
     |> clear_selected()}
  end

  def handle_event("clear_search", _params, socket) do
    {:noreply,
     socket
     |> clear_search()}
  end

  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> update(:rider_search, &RiderSearch.filter(&1, []))
     |> fetch_results()
     |> clear_search()
     |> clear_selected()}
  end

  def handle_event("choose", %{"choose" => choose}, socket) do
    {:noreply, assign(socket, search: choose)}
  end

  def handle_event("suggest", %{"value" => search}, socket) do
    {:noreply,
     socket
     |> update(:suggestions, &Suggestions.suggest(&1, search))
     |> assign(:search, search)
     |> assign(:show_suggestions, true)}
  end

  def handle_event("remove_filter", %{"index" => i}, socket) do
    filters = List.delete_at(socket.assigns.rider_search.filters, i)

    {:noreply,
     socket
     |> update(:rider_search, &RiderSearch.filter(&1, filters))
     |> fetch_results()
     |> remove_selected_riders()}
  end

  def handle_event(
        "select_rider",
        %{"_target" => ["selected", "all"], "selected" => %{"all" => select_all}},
        socket
      ) do
    selected =
      case select_all do
        "true" ->
          for r <- socket.assigns.search_results.page, into: MapSet.new(), do: r.id

        "false" ->
          MapSet.new()
      end

    {:noreply, assign(socket, :selected, selected)}
  end

  def handle_event(
        "select_rider",
        %{"_target" => ["selected", id], "selected" => selected_params},
        socket
      ) do
    selected =
      case selected_params[id] do
        "true" ->
          MapSet.put(socket.assigns.selected, String.to_integer(id))

        "false" ->
          MapSet.delete(socket.assigns.selected, String.to_integer(id))
      end

    {:noreply, assign(socket, :selected, selected)}
  end

  def handle_event("sort", %{"field" => field, "order" => order}, socket) do
    field = String.to_existing_atom(field)
    order = String.to_existing_atom(order)

    {:noreply,
     socket
     |> update(:rider_search, &RiderSearch.sort(&1, field, order))
     |> fetch_results()
     |> remove_selected_riders()}
  end

  def handle_event("next_page", _params, socket) do
    {:noreply,
     socket
     |> update(:rider_search, &RiderSearch.next_page/1)
     |> fetch_results()}
  end

  def handle_event("prev_page", _params, socket) do
    {:noreply,
     socket
     |> update(:rider_search, &RiderSearch.prev_page/1)
     |> fetch_results()}
  end

  def handle_event("set_mode", %{"mode" => mode}, socket) do
    {:noreply,
     socket
     |> assign(:all_locations, [])
     |> assign(:mode, String.to_existing_atom(mode))
     |> fetch_results()}
  end

  def handle_event(
        "map_click_rider",
        %{"id" => rider_id},
        socket
      ) do
    selected = socket.assigns.selected

    socket =
      if MapSet.member?(selected, rider_id) do
        socket
        |> assign(:selected, MapSet.delete(selected, rider_id))
        |> push_event("update_layer", %{
          id: rider_id,
          type: :marker,
          data: %{color: @unselected_color}
        })
      else
        socket
        |> assign(:selected, MapSet.put(selected, rider_id))
        |> push_event("update_layer", %{
          id: rider_id,
          type: :marker,
          data: %{color: @selected_color}
        })
      end

    {:noreply, socket}
  end

  defp parse_filter(value) do
    case String.split(value, ":", parts: 2) do
      ["program", search] ->
        if program = Delivery.get_program_by_name(search) do
          %Filter{type: :program, search: search, id: program.id}
        end

      [type, search] ->
        %Filter{type: String.to_atom(type), search: search}

      [search] ->
        %Filter{type: :name, search: String.trim(search)}
    end
  end

  defp display_search(%{"type" => type, "search" => search}) do
    "#{type}:#{search}"
  end

  defp display_search(search) when is_binary(search) do
    case String.split(search, ":", parts: 2) do
      [filter] -> filter
      ["name", filter] -> filter
      [_type, _filter] -> search
    end
  end

  defp clear_search(socket) do
    socket
    |> assign(:search, "")
    |> assign(:suggestions, %Suggestions{})
    |> assign(:show_suggestions, false)
  end

  defp clear_selected(socket) do
    socket
    |> assign(:selected, MapSet.new())
  end

  defp remove_selected_riders(socket) do
    selected =
      socket.assigns.search_results.page
      |> Enum.map(& &1.id)
      |> MapSet.new()
      |> MapSet.intersection(socket.assigns.selected)

    socket
    |> assign(:selected, selected)
  end

  defp fetch_results(socket) do
    {rider_search, search_results} =
      RiderSearch.fetch(socket.assigns.rider_search, socket.assigns.search_results)

    socket
    |> assign(:rider_search, rider_search)
    |> assign(:search_results, search_results)
    |> maybe_fetch_location()
  end

  defp maybe_fetch_location(socket) do
    # Only fetch locations when we're in map mode
    if socket.assigns.mode == :map do
      all_locations = RiderSearch.fetch_locations(socket.assigns.rider_search)

      added = all_locations -- socket.assigns.all_locations
      removed = socket.assigns.all_locations -- all_locations

      socket
      |> assign(:all_locations, all_locations)
      |> push_event(
        "add_layers",
        %{layers: rider_markers(added, socket.assigns.selected)}
      )
      |> push_event(
        "remove_layers",
        %{layers: for({id, _, _} <- removed, do: %{id: id})}
      )
    else
      socket
    end
  end

  defp rider_markers(locations, selected) do
    for {id, name, location} <- locations do
      color =
        if MapSet.member?(selected, id) do
          @selected_color
        else
          @unselected_color
        end

      %{
        id: id,
        type: :marker,
        data: %{
          lat: lat(location),
          lng: lng(location),
          icon: "bicycle",
          color: color,
          clickEvent: "map_click_rider",
          clickValue: %{id: id},
          tooltip: name
        }
      }
    end
  end

  defp suggestion_list(assigns) do
    ~H"""
    <dialog
      id="suggestion-list"
      open={@open}
      class="absolute z-10 w-full p-2 mt-0 overflow-y-auto bg-white border rounded shadow-xl top-100 max-h-fit"
      phx-window-keydown="clear_search"
      phx-key="escape"
    >
      <p class="text-sm text-gray-500">Press Tab to cycle suggestions</p>
      <div class="grid grid-cols-2 gap-1">
        <div>
          <%= if @suggestions.name do %>
            <h3 class="my-1 text-xs font-medium tracking-wider text-left text-gray-500 uppercase">
              Name
            </h3>
            <div class="flex flex-col my-2">
              <.suggestion filter={@suggestions.name} />
            </div>
          <% end %>
          <%= if @suggestions.phone do %>
            <h3 class="my-1 text-xs font-medium tracking-wider text-left text-gray-500 uppercase">
              Phone
            </h3>
            <div class="flex flex-col my-2">
              <.suggestion filter={@suggestions.phone} />
            </div>
          <% end %>
          <%= if @suggestions.tags != [] do %>
            <h3 class="my-1 text-xs font-medium tracking-wider text-left text-gray-500 uppercase">
              Tag
            </h3>
            <div class="flex flex-col my-2">
              <%= for tag <- @suggestions.tags do %>
                <.suggestion filter={tag} />
              <% end %>
            </div>
          <% end %>
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
        </div>
        <div>
          <%= if @suggestions.capacity != [] do %>
            <h3 class="my-1 text-xs font-medium tracking-wider text-left text-gray-500 uppercase">
              Capacity
            </h3>
            <div class="flex flex-col my-2">
              <%= for capacity <- @suggestions.capacity do %>
                <.suggestion filter={capacity} />
              <% end %>
            </div>
          <% end %>
          <%= if @suggestions.active != [] do %>
            <h3 class="my-1 text-xs font-medium tracking-wider text-left text-gray-500 uppercase">
              Last Active
            </h3>
            <div class="flex flex-col my-2">
              <%= for period <- @suggestions.active do %>
                <.suggestion filter={period} />
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </dialog>
    """
  end

  defp suggestion(assigns) do
    ~H"""
    <div id={dom_id(@filter)} class="px-1 py-0.5 rounded-md focus-within:bg-gray-100">
      <button
        type="button"
        phx-click={add_filter(@filter)}
        class="block ml-1 transition duration-150 ease-in-out w-fit hover:bg-gray-50 focus:outline-none focus:bg-gray-50"
        tabindex="1"
        phx-focus={JS.push("choose", value: %{"choose" => @filter})}
      >
        <p class={"px-2.5 py-1.5 rounded-md text-md font-medium #{color(@filter.type)}"}>
          <%= case @filter.type do %>
            <% :name -> %>
              "<%= @filter.search %>"<span class="ml-1 text-sm">in name</span>
            <% :phone -> %>
              "<%= @filter.search %>"<span class="ml-1 text-sm">in phone number</span>
            <% :program -> %>
              <span class="mr-0.5 text-sm"><%= @filter.type %>:</span><%= @filter.search %>
            <% _ -> %>
              <span class="mr-0.5 text-sm"><%= @filter.type %>:</span><%= @filter.search %>
          <% end %>
        </p>
      </button>
    </div>
    """
  end

  defp dom_id(%Filter{type: type, id: id}) when not is_nil(id) do
    "#{type}-#{id}"
  end

  defp dom_id(%Filter{type: type, search: search}) do
    "#{type}-#{search}"
  end

  defp filter_list(assigns) do
    ~H"""
    <%= if @filters != [] do %>
      <div class="flex flex-wrap space-x-0.5 max-w-xs">
        <%= for {%Filter{type: type, search: search}, i} <- Enum.with_index(@filters) do %>
          <div class={
            "my-0.5 inline-flex items-center px-2.5 py-1.5 rounded-md text-md font-medium #{color(type)}"
          }>
            <span class="text-700 mr-0.5 font-base"><%= type %>:</span><%= search %>
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

  defp show_phone_if_filtered(assigns) do
    assigns = assign(assigns, :phone_filter, get_filter(assigns.filters, :phone))

    ~H"""
    <div :if={@phone_filter} class="flex">
      <Heroicons.device_phone_mobile mini class="w-4 h-4" />
      <.bold_search string={@phone} search={@phone_filter} />
    </div>
    """
  end

  defp bold_search(assigns) do
    assigns = assign_new(assigns, :search_type, fn -> :any end)

    case assigns.search do
      nil ->
        ~H(<%= @string %>)

      "" ->
        ~H(<span class="font-bold"><%= @string %></span>)

      search ->
        pattern =
          case assigns.search_type do
            :any -> ~r/#{search}/i
            :word_boundary -> ~r/(^| )#{search}/i
          end

        segments =
          Regex.split(pattern, assigns.string, include_captures: true)
          |> Enum.chunk_every(2, 2, [""])

        assigns = assign(assigns, segments: segments)

        # Note the output is all one line cuz inline elements add spacing from spaces - which may be in the string
        ~H"""
        <%= raw(for [s, search] <- @segments, do: ~s(#{s}<span class="font-bold">#{search}</span>)) %>
        """
    end
  end

  defp color(type) do
    case type do
      :name -> "text-emerald-800 bg-emerald-100"
      :tag -> "text-indigo-800 bg-indigo-100"
      :program -> "text-indigo-800 bg-indigo-100"
      :active -> "text-amber-900 bg-amber-100"
      :capacity -> "text-rose-900 bg-rose-100"
      :phone -> "text-cyan-900 bg-cyan-100"
    end
  end

  defp get_filter(filters, type) do
    filters
    |> Enum.find_value(fn
      %Filter{type: ^type, search: search} -> search
      _ -> false
    end)
  end

  defp get_filter(filters, type, search) when is_atom(search) do
    get_filter(filters, type, Atom.to_string(search))
  end

  defp get_filter(filters, type, search) when is_binary(search) do
    filters
    |> Enum.find_value(fn
      %Filter{type: ^type, search: ^search} -> search
      _ -> false
    end)
  end

  defp add_filter(%Filter{} = filter) do
    JS.push("filter", value: filter)
  end

  defp add_filter(type, search) do
    JS.push("filter", value: %Filter{type: type, search: search})
  end
end
