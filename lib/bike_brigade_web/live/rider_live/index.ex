defmodule BikeBrigadeWeb.RiderLive.Index do
  use BikeBrigadeWeb, :live_view

  alias Phoenix.LiveView.JS

  alias BikeBrigade.Riders
  alias BikeBrigade.Riders.RiderSearch
  alias BikeBrigade.LocalizedDateTime

  defmodule SortOptions do
    # This is a streamlined version of the one from leaderboard.ex
    # Deciding if we need all the ecto stuff here

    defstruct [:field, :order, offset: 0, limit: 20]

    def to_tuple(%__MODULE__{field: field, order: order, offset: offset, limit: limit}) do
      {order, field, offset, limit}
    end
  end

  defmodule Suggestions do
    @actives ~w(hour day week month year)
    @capacities ~w(large medium small)

    defstruct name: nil, phone: nil, tags: [], active: [], capacity: []

    @type t :: %__MODULE__{
            name: String.t() | nil,
            tags: list(String.t()),
            active: list(String.t()),
            capacity: list(String.t())
          }

    @spec suggest(t(), String.t()) :: t()
    def suggest(suggestions, "") do
      %{suggestions | name: nil, tags: [], active: [], capacity: []}
    end

    def suggest(suggestions, search) do
      case String.split(search, ":", parts: 2) do
        ["tag", tag] ->
          tags =
            Riders.search_tags(tag)
            |> Enum.map(& &1.name)

          %__MODULE__{tags: tags}

        ["active", active] ->
          actives =
            @actives
            |> Enum.filter(&String.starts_with?(&1, active))

          %__MODULE__{active: actives}

        ["capacity", capacity] ->
          capacity =
            @capacities
            |> Enum.filter(&String.starts_with?(&1, capacity))

          %__MODULE__{capacity: capacity}

        [search] ->
          tags =
            if String.length(search) < 3 do
              Riders.list_tags()
            else
              Riders.search_tags(search)
            end
            |> Enum.map(& &1.name)

          phone =
            if search =~ ~r/^\d+$/ do
              search
            end

          %{
            suggestions
            | name: search,
              phone: phone,
              tags: tags,
              active: @actives,
              capacity: @capacities
          }

        [_, _] ->
          # unknown facet
          %__MODULE__{}
      end
    end
  end

  @default_rider_search RiderSearch.new(preload: [:tags, :latest_campaign])

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

  defp apply_action(socket, :index, params) do
    tag_filters =
      Map.get(params, "tag", [])
      |> Enum.map(fn tag -> {:tag, tag} end)

    capacity_filters =
      Map.get(params, "capacity", [])
      |> Enum.map(fn tag -> {:capacity, tag} end)

    rider_search =
      RiderSearch.new(
        filters: tag_filters ++ capacity_filters,
        preload: [:tags, :latest_campaign]
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
  def handle_event("filter", %{"value" => search}, socket) do
    filter = parse_filter(search)

    {:noreply,
     socket
     |> update(:rider_search, &RiderSearch.filter(&1, &1.filters ++ [filter]))
     |> fetch_results()
     |> clear_search()
     |> clear_selected()}
  end

  def handle_event("clear-search", _params, socket) do
    {:noreply,
     socket
     |> clear_search()}
  end

  def handle_event("clear-filters", _params, socket) do
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

  def handle_event("remove-filter", %{"index" => i}, socket) do
    i = String.to_integer(i)
    filters = List.delete_at(socket.assigns.rider_search.filters, i)

    {:noreply,
     socket
     |> update(:rider_search, &RiderSearch.filter(&1, filters))
     |> fetch_results()
     |> remove_selected_riders()}
  end

  def handle_event(
        "select-rider",
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
        "select-rider",
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

  def handle_event(
        "select-rider",
        %{"_target" => ["selected", "all"], "selected" => selected_params},
        socket
      ) do
    %{opportunities: opportunities} = socket.assigns

    selected =
      case selected_params["all"] do
        "true" -> Enum.map(opportunities, & &1.id) |> MapSet.new()
        "false" -> MapSet.new()
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

  def handle_event("next-page", _params, socket) do
    {:noreply,
     socket
     |> update(:rider_search, &RiderSearch.next_page/1)
     |> fetch_results()}
  end

  def handle_event("prev-page", _params, socket) do
    {:noreply,
     socket
     |> update(:rider_search, &RiderSearch.prev_page/1)
     |> fetch_results()}
  end

  def handle_event("set-mode", %{"mode" => mode}, socket) do
    {:noreply,
     socket
     |> assign(:all_locations, [])
     |> assign(:mode, String.to_existing_atom(mode))
     |> fetch_results()}
  end

  def handle_event(
        "map-click-rider",
        %{"id" => rider_id},
        socket
      ) do
    selected = socket.assigns.selected

    socket =
      if MapSet.member?(selected, rider_id) do
        socket
        |> assign(:selected, MapSet.delete(selected, rider_id))
        |> push_event("update-marker", %{id: rider_id, icon: "bicycle", color: @unselected_color})
      else
        socket
        |> assign(:selected, MapSet.put(selected, rider_id))
        |> push_event("update-marker", %{id: rider_id, icon: "bicycle", color: @selected_color})
      end

    {:noreply, socket}
  end

  defp parse_filter(search) do
    case String.split(search, ":", parts: 2) do
      [type, filter] ->
        type = String.to_atom(type)
        filter = String.trim(filter)

        {type, filter}

      [filter] ->
        {:name, String.trim(filter)}
    end
  end

  defp display_search(search) do
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
      |> push_event("update-markers", %{
        added: rider_markers(added, socket.assigns.selected),
        removed: for({id, _, _} <- removed, do: %{id: id})
      })
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
        lat: lat(location),
        lng: lng(location),
        icon: "bicycle",
        color: color,
        clickEvent: "map-click-rider",
        clickValue: %{id: id},
        tooltip: name
      }
    end
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <%= if @live_action == :message do %>
        <UI.modal id={:bulk_message} show return_to={Routes.rider_index_path(@socket, :index)} >
          <:title>Bulk Message</:title>
          <.live_component
            module={BikeBrigadeWeb.SmsMessageLive.FormComponent}
            id={:bulk_message}
            initial_riders={@initial_riders}
            current_user={@current_user}/>
        </UI.modal>
      <% end %>
      <div class="flex items-center justify-between ">
        <div class="relative flex flex-col w-2/3">
          <form id="rider-search" phx-change="suggest" phx-submit="filter"}
            phx-click-away="clear-search">
            <div class="relative flex items-baseline w-full px-1 py-0 bg-white border border-gray-300 rounded-md shadow-sm sm:text-sm focus-within:ring-1 focus-within:ring-indigo-500 focus-within:border-indigo-500">
              <.filter_list filters={@rider_search.filters} />
              <input type="text"
                id="rider-search-input"
                name="value"
                value={display_search(@search)}
                autocomplete="off"
                class="w-full placeholder-gray-400 border-transparent appearance-none focus:border-transparent outline-transparent ring-transparent focus:ring-0"
                placeholder="Name, tag, capacity, last active"
                tabindex="1"/>
                <%= if @rider_search.filters != [] do %>
                    <button type="button" phx-click="clear-filters" class="absolute right-1 text-gray-400 rounded-md top-2.5 hover:text-gray-500">
                      <span class="sr-only">Clear Search</span>
                      <Heroicons.Outline.x class="w-6 h-6" />
                    </button>
                <% end %>
              </div>
          <.suggestion_list suggestions={@suggestions} open={@show_suggestions}/>
          <button id="submit" type="submit" class="sr-only"/>
          </form>
        </div>
        <div class="inline-flex rounded-md shadow-sm">
          <button phx-click="set-mode" phx-value-mode="list" type="button" class={"#{if @mode == :list, do: "bg-gray-300", else: "bg-white"} relative inline-flex items-center px-4 py-2 text-sm font-medium text-gray-700 border border-gray-300 rounded-l-md hover:bg-gray-200 focus:z-10 focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500"}>
            <Heroicons.Outline.table class="w-5 h-5 mr-1" />
            List
          </button>
          <button phx-click="set-mode" phx-value-mode="map" type="button" class={"#{if @mode == :map, do: "bg-gray-300", else: "bg-white"} relative inline-flex items-center px-4 py-2 -ml-px text-sm font-medium text-gray-700 border border-gray-300 rounded-r-md hover:bg-gray-200 focus:z-10 focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500"}>
            Map
            <Heroicons.Outline.map class="w-5 h-5 ml-1" />
          </button>
        </div>
        <C.button patch_to={Routes.rider_index_path(@socket, :message)}>
          Bulk Message
          <%= if MapSet.size(@selected) > 0 do %>
            (<%= MapSet.size(@selected) %>)
          <% end %>
        </C.button>
      </div>
      <form id="selected" phx-change="select-rider"></form>
      <%= if @mode == :map do %>
        <div class="min-w-full mt-2 bg-white rounded-lg shadow">
          <div class="p-1 h-[80vh]">
            <.rider_map rider_locations={@all_locations} selected={@selected} lat={43.653960} lng={-79.425820} />
          </div>
          <div class="flex items-center justify-between px-4 py-3 border-t border-gray-200 sm:px-6" aria-label="Pagination">
            <div class="hidden sm:block">
              <p class="text-sm text-gray-700">
                Showing
                <span class="font-medium">
                <%= @search_results.total %>
                </span>
                results
              </p>
            </div>
          </div>
        </div>
      <% else %>
        <UI.table id="riders" rows={@search_results.page} class="min-w-full mt-2">
          <:th class="text-center" padding="px-3">
          <%= checkbox :selected, :all,
            form: "selected",
            value: all_selected?(@search_results.page, @selected),
            class: "w-4 h-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500" %>
          </:th>
          <:th padding="px-3">
            <div class="inline-flex">
              Name
              <C.sort_link phx-click="sort" current_field={:name} default_order={:asc} sort_field={@rider_search.sort_field} sort_order={@rider_search.sort_order} class="pl-2" />
            </div>
          </:th>
          <:th>
            Location
          </:th>
          <:th>
            Tags
          </:th>
          <:th>
            <div class="inline-flex">
              Capacity
              <C.sort_link phx-click="sort" current_field={:capacity} default_order={:desc} sort_field={@rider_search.sort_field} sort_order={@rider_search.sort_order} class="pl-2" />
            </div>
          </:th>
          <:th>
            <div class="inline-flex">
              Last Active
              <C.sort_link phx-click="sort" current_field={:last_active} default_order={:desc} sort_field={@rider_search.sort_field} sort_order={@rider_search.sort_order} class="pl-2" />
            </div>
          </:th>

          <:td let={rider} class="text-center" padding="px-3">
            <%= checkbox :selected, "#{rider.id}",
              form: "selected",
              value: MapSet.member?(@selected, rider.id),
              class: "w-4 h-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500" %>
          </:td>
          <:td let={rider} padding="px-3">
            <%= live_redirect to: Routes.rider_show_path(@socket, :show, rider), class: "link" do %>
              <.bold_search string={rider.name} search={get_filter(@rider_search.filters, :name)} search_type={:word_boundary} />
            <% end %>
            <span class="text-xs lowercase ">(<%= rider.pronouns %>)</span>
            <.show_phone_if_filtered phone={rider.phone} filters={@rider_search.filters} />
          </:td>
          <:td let={rider}>
            <%= rider.location_struct.neighborhood %>
          </:td>
          <:td let={rider}>
            <ul class="flex">
              <%= for tag <- rider.tags do %>
              <li class="before:content-[','] first:before:content-['']">
                <button type="button" phx-click="filter" value={"tag:#{tag.name}"}}
                  class="link">
                  <%= if get_filter(@rider_search.filters, :tag, tag.name) do %>
                    <span class="font-bold"><%= tag.name %></span>
                  <% else %>
                    <%= tag.name %>
                  <% end %>
                </button>
              </li>
              <% end %>
            </ul>
          </:td>
          <:td let={rider}>
            <button type="button" phx-click="filter" value={"capacity:#{rider.capacity}"}}
            class="link">
              <%= if get_filter(@rider_search.filters, :capacity, rider.capacity) do %>
                <span class="font-bold"><%= rider.capacity %></span>
              <% else %>
                <%= rider.capacity %>
              <% end %>
            </button>
          </:td>
          <:td let={rider}>
            <%= if rider.latest_campaign do %>
              <%=  rider.latest_campaign.delivery_start |> LocalizedDateTime.to_date() |> Calendar.strftime("%b %-d, %Y") %>
            <% end %>
          </:td>
          <:footer>
            <nav class="flex items-center justify-between px-4 py-3 bg-white border-t border-gray-200 sm:px-6" aria-label="Pagination">
              <div class="hidden sm:block">
                <p class="text-sm text-gray-700">
                  Showing
                  <span class="font-medium">
                    <%= @search_results.page_first %>
                  </span>
                  to
                  <span class="font-medium">
                    <%= @search_results.page_last %>
                  </span>
                  of
                  <span class="font-medium">
                  <%= @search_results.total %>
                  </span>
                  results
                </p>
              </div>
              <div class="flex justify-between flex-1 sm:justify-end">
                <%= if RiderSearch.Results.has_prev_page?(@search_results) do %>
                  <C.button phx-click="prev-page" color={:white}>
                    Previous
                  </C.button>
                <% end %>

                <%= if RiderSearch.Results.has_next_page?(@search_results) do %>
                  <C.button phx-click="next-page" color={:white} class="ml-3">
                    Next
                  </C.button>
                <% end %>
              </div>
            </nav>
          </:footer>
        </UI.table>
      <% end %>
    </div>
    """
  end

  defp suggestion_list(assigns) do
    ~H"""
    <dialog id="suggestion-list"
      open={@open}
      class="absolute z-10 w-full p-2 mt-0 overflow-y-auto bg-white border rounded shadow-xl top-100 max-h-fit"
      phx-window-keydown="clear-search" phx-key="escape">
      <p class="text-sm text-gray-500">Press Tab to cycle suggestions</p>
      <div class="grid grid-cols-2 gap-1">
      <div>
      <%= if @suggestions.name do %>
        <h3 class="my-1 text-xs font-medium tracking-wider text-left text-gray-500 uppercase">
          Name
        </h3>
        <div class="flex flex-col my-2">
          <.suggestion type={:name} search={@suggestions.name} />
        </div>
      <% end %>
      <%= if @suggestions.phone do %>
        <h3 class="my-1 text-xs font-medium tracking-wider text-left text-gray-500 uppercase">
          Phone
        </h3>
        <div class="flex flex-col my-2">
          <.suggestion type={:phone} search={@suggestions.phone} />
        </div>
      <% end %>
      <%= if @suggestions.tags != [] do %>
        <h3 class="my-1 text-xs font-medium tracking-wider text-left text-gray-500 uppercase">
          Tag
        </h3>
        <div class="flex flex-col my-2">
          <%= for tag <- @suggestions.tags do %>
            <.suggestion type={:tag} search={tag} />
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
            <.suggestion type={:capacity} search={capacity} />
          <% end %>
        </div>
      <% end %>
      <%= if @suggestions.active != [] do %>
        <h3 class="my-1 text-xs font-medium tracking-wider text-left text-gray-500 uppercase">
          Last Active
        </h3>
        <div class="flex flex-col my-2">
          <%= for period <- @suggestions.active do %>
            <.suggestion type={:active} search={period} />
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
    <div id={"#{@type}-#{@search}"} class="px-1 py-0.5 rounded-md focus-within:bg-gray-100">
      <button type="button" phx-click="filter" value={"#{@type}:#{@search}"}
        class="block ml-1 transition duration-150 ease-in-out w-fit hover:bg-gray-50 focus:outline-none focus:bg-gray-50"
        tabindex="1"
        phx-focus={JS.push("choose", value: %{"choose" => "#{@type}:#{@search}"})}>
        <p class={"px-2.5 py-1.5 rounded-md text-md font-medium #{color(@type)}"}>
          <%= case @type do %>
          <% :name -> %>
            "<%= @search %>"<span class="ml-1 text-sm">in name</span>
          <% :phone -> %>
            "<%= @search %>"<span class="ml-1 text-sm">in phone number</span>
          <% _ -> %>
            <span class="mr-0.5 text-sm"><%= @type %>:</span><%= @search %>
          <% end %>
        </p>
      </button>
    </div>
    """
  end

  defp filter_list(assigns) do
    ~H"""
    <%= if @filters != [] do %>
      <div class="flex flex-wrap space-x-0.5 max-w-xs">
        <%= for {{type, search}, i} <- Enum.with_index(@filters) do %>
          <div class={"my-0.5 inline-flex items-center px-2.5 py-1.5 rounded-md text-md font-medium #{color(type)}"}>
            <span class="text-700 mr-0.5 font-base"><%= type %>:</span><%= search %>
            <Heroicons.Outline.x_circle class="w-5 h-5 ml-1 cursor-pointer" phx-click="remove-filter" phx-value-index={i} />
          </div>
        <% end  %>
      </div>
    <% end %>
    """
  end

  def rider_map(assigns) do
    ~H"""
    <div phx-hook="LeafletMapNext" id="task-map"
        data-mapbox_access_token="pk.eyJ1IjoibXZleXRzbWFuIiwiYSI6ImNrYWN0eHV5eTBhMTMycXI4bnF1czl2ejgifQ.xGiR6ANmMCZCcfZ0x_Mn4g"
        data-lat={@lat} data-lng={@lng}
        phx-update="ignore"
        class="h-full">
    </div>
    """
  end

  defp show_phone_if_filtered(assigns) do
    if phone_filter = get_filter(assigns.filters, :phone) do
      ~H"""
      <div class="flex">
        <Heroicons.Outline.phone class="w-4 h-4" />
        <.bold_search string={@phone} search={phone_filter} />
      </div>
      """
    else
      ~H""
    end
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
          <%= for [s, search] <- @segments do %><%= s %><span class="font-bold"><%= search %></span><% end %>
        """
    end
  end

  defp color(type) do
    case type do
      :name -> "text-emerald-800 bg-emerald-100"
      :tag -> "text-indigo-800 bg-indigo-100"
      :active -> "text-amber-900 bg-amber-100"
      :capacity -> "text-rose-900 bg-rose-100"
      :phone -> "text-cyan-900 bg-cyan-100"
    end
  end

  defp all_selected?(riders, selected) do
    MapSet.size(selected) != 0 && Enum.count(riders) == MapSet.size(selected)
  end

  defp get_filter(filters, kind) when is_atom(kind) do
    filters
    |> Enum.find_value(fn
      {^kind, filter} -> filter
      _ -> false
    end)
  end

  defp get_filter(filters, kind, filter) when is_atom(kind) and is_binary(filter) do
    filters
    |> Enum.find_value(fn
      {^kind, ^filter} -> filter
      _ -> false
    end)
  end

  defp get_filter(filters, kind, filter) when is_atom(kind) and is_atom(filter) do
    get_filter(filters, kind, Atom.to_string(filter))
  end
end
