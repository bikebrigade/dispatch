defmodule BikeBrigadeWeb.RiderLive.IndexNext do
  use BikeBrigadeWeb, :live_view

  alias Phoenix.LiveView.JS

  alias BikeBrigade.Repo
  alias BikeBrigade.Riders
  alias BikeBrigade.LocalizedDateTime

  alias BikeBrigadeWeb.Components.Icons

  defmodule SortOptions do
    # This is a streamlined version of the one from leaderboard.ex
    # Deciding if we need all the ecto stuff here

    defstruct [:field, :order, offset: 0, limit: 20]

    def to_tuple(%__MODULE__{field: field, order: order, offset: offset, limit: limit}) do
      {order, field, offset, limit}
    end

    def link(%{field: field, sort_options: sort_options} = assigns) do
      assigns =
        case sort_options do
          %{field: ^field, order: order} ->
            # This field selected
            assign(assigns,
              icon_class: "w-5 h-5 text-gray-500 hover:text-gray-700",
              order: order,
              next: next(order)
            )

          _ ->
            # Another field selected
            assign(assigns,
              icon_class: "w-5 h-5 text-gray-300 hover:text-gray-700",
              order: :desc,
              next: :desc
            )
        end

      assigns =
        assign(
          assigns,
          :attrs,
          assigns_to_attributes(assigns, [:sort_options, :field, :order, :icon_class, :next])
        )

      ~H"""
      <button type="button" phx-value-field={@field} phx-value-order={@next} {@attrs}>
        <Icons.sort order={@order} class={@icon_class}/>
      </button>
      """
    end

    defp next(:desc), do: :asc
    defp next(:asc), do: :desc
  end

  defmodule Suggestions do
    @actives ~w(hour day week month year)

    defstruct name: nil, tags: [], active: []

    @type t :: %__MODULE__{
            name: String.t() | nil,
            tags: list(String.t()),
            active: list(atom())
          }

    @spec suggest(t(), String.t()) :: t()
    def suggest(suggestions, "") do
      %{suggestions | name: nil, tags: [], active: []}
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

        [search] ->
          tags =
            if String.length(search) < 3 do
              Riders.list_tags()
            else
              Riders.search_tags(search)
            end
            |> Enum.map(& &1.name)

          %{suggestions | name: [search], tags: tags, active: @actives}

        [_, _] ->
          # unknown facet
          %__MODULE__{}
      end
    end
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    sort_options = %SortOptions{field: :last_active, order: :desc}

    {:ok,
     socket
     |> assign(:page, :riders)
     |> assign(:selected, MapSet.new())
     |> assign(:sort_options, sort_options)
     |> assign(:search, "")
     |> assign(:queries, [])
     |> assign(:suggestions, %Suggestions{})
     |> assign(:show_suggestions, false)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, params) do
    queries =
      Map.get(params, "tags", [])
      |> Enum.map(fn tag -> {:tag, tag} end)

    socket
    |> assign(:queries, queries)
    |> fetch_riders(repaginate: true)
  end

  defp apply_action(socket, :message, _params) do
    riders =
      socket.assigns.selected
      |> MapSet.to_list()
      |> Riders.get_riders()

    socket
    |> assign(:initial_riders, riders)
  end

  @impl Phoenix.LiveView

  def handle_event("search", %{"value" => search}, socket) do
    query = parse_search(search)

    {:noreply,
     socket
     |> assign(:queries, socket.assigns.queries ++ query)
     |> clear_search()
     |> clear_selected()
     |> fetch_riders(repaginate: true)}
  end

  def handle_event("clear-search", _params, socket) do
    {:noreply,
     socket
     |> clear_search()}
  end

  def handle_event("clear-queries", _params, socket) do
    {:noreply,
     socket
     |> assign(:queries, [])
     |> clear_search()
     |> clear_selected()
     |> fetch_riders(repaginate: true)}
  end

  def handle_event("choose", %{"choose" => choose}, socket) do
    {:noreply, assign(socket, search: choose)}
  end

  def handle_event("suggest", %{"value" => search}, socket) do
    {:noreply,
     assign(socket,
       search: search,
       suggestions: Suggestions.suggest(socket.assigns.suggestions, search),
       show_suggestions: true
     )}
  end

  def handle_event("remove-query", %{"index" => i}, socket) do
    i = String.to_integer(i)

    {:noreply,
     socket
     |> assign(:queries, List.delete_at(socket.assigns.queries, i))
     |> fetch_riders(repaginate: true)}
  end

  def handle_event(
        "select-rider",
        %{"_target" => ["selected", "all"], "selected" => %{"all" => select_all}},
        socket
      ) do
    selected =
      case select_all do
        "true" ->
          for r <- socket.assigns.riders, into: MapSet.new(), do: r.id

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

  def handle_event("bulk-message", _params, socket) do
    rider_ids = socket.assigns.selected |> MapSet.to_list()

    {:noreply,
     push_redirect(socket,
       to: Routes.sms_message_index_path(socket, :new, r: rider_ids),
       replace: false
     )}
  end

  def handle_event("sort", %{"field" => field, "order" => order}, socket) do
    field = String.to_existing_atom(field)
    order = String.to_existing_atom(order)
    sort_options = %SortOptions{field: field, order: order}

    {:noreply,
     socket
     |> assign(:sort_options, sort_options)
     |> fetch_riders()}
  end

  def handle_event("next-page", _params, socket) do
    sort_options = socket.assigns.sort_options
    sort_options = %{sort_options | offset: sort_options.offset + sort_options.limit}

    {:noreply,
     socket
     |> assign(:sort_options, sort_options)
     |> fetch_riders()}
  end

  def handle_event("prev-page", _params, socket) do
    sort_options = socket.assigns.sort_options
    sort_options = %{sort_options | offset: sort_options.offset - sort_options.limit}

    {:noreply,
     socket
     |> assign(:sort_options, sort_options)
     |> fetch_riders()}
  end

  defp parse_search(search) do
    with [type, query] <- String.split(search, ":", parts: 2) do
      query = String.trim(query)

      case type do
        "name" -> [name: query]
        "tag" -> [tag: query]
        "active" -> [active: query]
      end
    else
      [query] -> [name: String.trim(query)]
    end
  end

  defp display_search(search) do
    case String.split(search, ":", parts: 2) do
      [query] -> query
      ["name", query] -> query
      [_type, _query] -> search
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

  defp fetch_riders(socket, search_opts \\ []) do
    sort = SortOptions.to_tuple(socket.assigns.sort_options)

    {socket, riders} =
      if Keyword.get(search_opts, :repaginate) do
        {riders, total} = Riders.search_riders_next(socket.assigns.queries, sort, total: true)

        socket =
          socket
          |> assign(:total, total)
          |> assign(:sort_options, %{socket.assigns.sort_options | offset: 0})

        {socket, riders}
      else
        {riders, nil} = Riders.search_riders_next(socket.assigns.queries, sort)
        {socket, riders}
      end

    riders =
      riders
      |> Repo.preload([:tags, :latest_campaign])

    selected =
      riders
      |> Enum.map(& &1.id)
      |> MapSet.new()
      |> MapSet.intersection(socket.assigns.selected)

    socket
    |> assign(:riders, riders)
    |> assign(:selected, selected)
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <%= if @live_action == :message do %>
        <UI.modal id={:new_message} show return_to={Routes.rider_index_next_path(@socket, :index)} >
          <:title>Bulk Message</:title>
          <.live_component
            module={BikeBrigadeWeb.SmsMessageLive.FormComponent}
            id={:new_message}
            initial_riders={@initial_riders}/>
        </UI.modal>
      <% end %>
      <div class="flex items-baseline justify-between ">
        <div class="relative flex flex-col w-2/3">
          <form id="rider-search" phx-change="suggest" phx-submit="search"}
            phx-click-away="clear-search">
            <div class="relative flex items-baseline w-full px-1 py-0 bg-white border border-gray-300 rounded-md shadow-sm sm:text-sm focus-within:ring-1 focus-within:ring-indigo-500 focus-within:border-indigo-500">
              <.query_list queries={@queries} />
              <input type="text"
                id="rider-search-input"
                name="value"
                value={display_search(@search)}
                autocomplete="off"
                class="w-full placeholder-gray-400 border-transparent appearance-none focus:border-transparent outline-transparent ring-transparent focus:ring-0"
                placeholder="Name, email, phone, tag, neighborhood"
                tabindex="1"/>
                <%= if @queries != [] do %>
                    <button type="button" phx-click="clear-queries" class="absolute right-1 text-gray-400 rounded-md top-2.5 hover:text-gray-500">
                      <span class="sr-only">Clear Search</span>
                      <Heroicons.Outline.x class="w-6 h-6" />
                    </button>
                <% end %>
              </div>
          <.suggestion_list suggestions={@suggestions} open={@show_suggestions}/>
          <button id="submit" type="submit" class="sr-only"/>
          </form>
        </div>
        <C.button patch_to={Routes.rider_index_next_path(@socket, :message)}>Bulk Message</C.button>
      </div>
      <form id="selected" phx-change="select-rider"></form>
      <UI.table rows={@riders} class="mt-2">
        <:th class="text-center" padding="px-3">
        <%= checkbox :selected, :all,
          form: "selected",
          value: all_selected?(@riders, @selected),
          class: "w-4 h-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500" %>
        </:th>
        <:th padding="px-3">
          <div class="inline-flex">
            Name
            <SortOptions.link phx-click="sort" field={:name} sort_options={@sort_options} class="pl-2" />
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
            Last Active
            <SortOptions.link phx-click="sort" field={:last_active} sort_options={@sort_options} class="pl-2"/>
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
            <%= rider.name %><span class="ml-1 text-xs lowercase ">(<%= rider.pronouns %>)</span>
          <% end %>
        </:td>
        <:td let={rider}>
          <%= rider.location_struct.neighborhood %>
        </:td>
        <:td let={rider}>
          <ul class="flex">
            <%= for tag <- rider.tags do %>
            <li class="before:content-[','] first:before:content-['']">
              <button type="button" phx-click="search" value={"tag:#{tag.name}"}}
                class="link">
                <%= tag.name %>
              </button>
            </li>
            <% end %>
          </ul>
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
                  <%= @sort_options.offset + 1 %>
                </span>
                to
                <span class="font-medium">
                  <%= @sort_options.offset + Enum.count(@riders) %>
                </span>
                of
                <span class="font-medium">
                <%= @total %>
                </span>
                results
              </p>
            </div>
            <div class="flex justify-between flex-1 sm:justify-end">
              <%= if @sort_options.offset > 0 do %>
                <C.button phx-click="prev-page" color={:white}>
                  Previous
                </C.button>
              <% end %>

              <%= if @sort_options.offset + @sort_options.limit < @total do %>
                <C.button phx-click="next-page" color={:white} class="ml-3">
                  Next
                </C.button>
              <% end %>
            </div>
          </nav>
        </:footer>
      </UI.table>
    </div>
    """
  end

  defp suggestion_list(assigns) do
    ~H"""
    <dialog id="suggestion-list2"
      open={@open}
      class="absolute w-full p-2 mt-0 overflow-y-auto bg-white border rounded shadow-xl top-100 max-h-64"
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
      <%= if @suggestions.active != [] do %>
        <div>
          <h3 class="my-1 text-xs font-medium tracking-wider text-left text-gray-500 uppercase">
            Last Active
          </h3>
          <div class="flex flex-col my-2">
            <%= for period <- @suggestions.active do %>
              <.suggestion type={:active} search={period} />
            <% end %>
          </div>
        </div>
      <% end %>
      </div>
    </dialog>
    """
  end

  defp suggestion(assigns) do
    ~H"""
    <div id={"#{@type}-#{@search}"} class="px-1 py-0.5 rounded-md focus-within:bg-gray-100">
      <button type="button" phx-click="search" value={"#{@type}:#{@search}"}
        class="block ml-1 transition duration-150 ease-in-out w-fit hover:bg-gray-50 focus:outline-none focus:bg-gray-50"
        tabindex="1"
        phx-focus={JS.push("choose", value: %{"choose" => "#{@type}:#{@search}"})}>
        <p class={"px-2.5 py-1.5 rounded-md text-md font-medium #{color(@type)}"}>
          <%= if @type == :name do %>
            "<%= @search %>"<span class="ml-1 text-sm">in name</span>
          <% else %>
            <span class="mr-0.5 text-sm"><%= @type %>:</span><%= @search %>
          <% end %>
        </p>
      </button>
    </div>
    """
  end

  defp query_list(assigns) do
    ~H"""
    <%= if @queries != [] do %>
      <div class="flex flex-wrap space-x-0.5 max-w-xs">
        <%= for {{type, search}, i} <- Enum.with_index(@queries) do %>
          <div class={"my-0.5 inline-flex items-center px-2.5 py-1.5 rounded-md text-md font-medium #{color(type)}"}>
            <span class="text-700 mr-0.5 font-base"><%= type %>:</span><%= search %>
            <Heroicons.Outline.x_circle class="w-5 h-5 ml-1 cursor-pointer" phx-click="remove-query" phx-value-index={i} />
          </div>
        <% end  %>
      </div>
    <% end %>
    """
  end

  defp color(type) do
    case type do
      :name -> "text-emerald-800 bg-emerald-100"
      :tag -> "text-indigo-800 bg-indigo-100"
      :active -> "text-amber-900 bg-amber-100"
    end
  end

  defp all_selected?(riders, selected) do
    MapSet.size(selected) != 0 && Enum.count(riders) == MapSet.size(selected)
  end
end
