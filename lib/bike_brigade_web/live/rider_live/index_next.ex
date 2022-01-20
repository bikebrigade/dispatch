defmodule BikeBrigadeWeb.RiderLive.IndexNext do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.Repo
  alias BikeBrigade.Riders
  alias BikeBrigade.Delivery
  alias BikeBrigade.LocalizedDateTime

  alias BikeBrigadeWeb.Components.Icons

  defmodule SortOptions do
    # This is a streamlined version of the one from leaderboard.ex
    # Deciding if we need all the ecto stuff here

    defstruct [:field, :order]

    def to_tuple(%__MODULE__{field: field, order: order}) do
      {order, field}
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

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    sort_options = %SortOptions{field: :name, order: :asc}

    {:ok,
     socket
     |> assign(:page, :riders)
     |> assign(:selected, MapSet.new())
     |> assign(:sort_options, sort_options)
     |> assign(:search, "")
     |> assign(:queries, [])
     |> assign(:suggestions, [])
     |> fetch_riders()}
  end

  @impl Phoenix.LiveView

  def handle_event("search", %{"type" => type, "search" => search}, socket) do
    query = case type do
      "name" -> [name: String.trim(search)]
      "tag" -> [tag: search]
    end

    {:noreply,
     socket
     |> assign(:queries, socket.assigns.queries ++ query)
     |> clear_search()
     |> fetch_riders()}
  end

  def handle_event("suggest", %{"value" => search}, socket) do
    {:noreply, assign(socket, search: search, suggestions: suggestions(search))}
  end

  def handle_event("remove-query", %{"index" => i}, socket) do
    i = String.to_integer(i)

    {:noreply,
     socket
     |> assign(:queries, List.delete_at(socket.assigns.queries, i))
     |> fetch_riders()}
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

  defp suggestions("") do
    []
  end

  defp suggestions(search) do
    for t <- Riders.search_tags(search) do
      {:tag, t.name}
    end ++
      [name: search]
  end

  defp clear_search(socket) do
    socket
    |> assign(:search, "")
    |> assign(:suggestions, [])
  end

  defp fetch_riders(socket) do
    sort = SortOptions.to_tuple(socket.assigns.sort_options)

    riders =
      Riders.search_riders_next(socket.assigns.queries, sort)
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
      <div class="flex items-baseline justify-between ">
        <div class="relative w-2/3">
          <.query_list queries={@queries} />
          <input type="text" phx-keydown="suggest" phx-debounce="100"
            value={}
            class="block w-full px-3 py-2 placeholder-gray-400 border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
            placeholder="Name, email, phone, tag, neighborhood" />
          <.suggestion_list suggestions={@suggestions} />
        </div>
        <C.button phx-click="bulk-message">Bulk Message</C.button>
      </div>
      <form id="selected" phx-change="select-rider"></form>
      <UI.table rows={@riders} class="mt-2">
        <:th class="text-center" padding="px-3">
        <%= checkbox :selected, :all,
          form: "selected",
          value: Enum.count(@selected) == Enum.count(@riders),
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
          <%= rider.tags |> Enum.map(& &1.name) |> Enum.join(", ") %>
        </:td>
        <:td let={rider}>
          <%= if rider.latest_campaign do %>
            <%=  rider.latest_campaign.delivery_start |> LocalizedDateTime.to_date() |> Calendar.strftime("%b %-d, %Y") %>
          <% end %>
        </:td>
      </UI.table>
    </div>
    """
  end

  defp suggestion_list(%{suggestions: []} = assigns) do
    ~H""
  end

  defp suggestion_list(assigns) do
    ~H"""
    <ul id="suggestion-list" class="absolute w-full p-1 mt-1 overflow-y-auto bg-white border rounded shadow-xl top-100 max-h-64">
      <%= for {type, search} <- @suggestions do %>
        <li class="p-1">
          <.suggestion type={type} search={search} />
        </li>
      <% end %>
    </ul>
    """
  end

  defp suggestion(assigns) do


    ~H"""
    <a href="#" phx-click="search" phx-value-type={@type} phx-value-search={@search} class="block transition duration-150 ease-in-out w-fit hover:bg-gray-50 focus:outline-none focus:bg-gray-50">
      <p class={"px-2.5 py-1.5 rounded-md text-md font-medium #{color(@type)}"}>
        <span class="mr-0.5 text-sm"><%= @type %>:</span><%= @search %>
      </p>
    </a>
    """
  end

  defp query_list(assigns) do
    ~H"""
    <%= for {{type, search}, i} <- Enum.with_index(@queries) do %>
      <div class={"my-0.5 inline-flex items-center px-2.5 py-1.5 rounded-md text-md font-medium #{color(type)}"}>
        <span class="text-700 mr-0.5 font-base"><%= type %></span><%= search %>
        <Heroicons.Outline.x_circle class="w-5 h-5 ml-1 cursor-pointer" phx-click="remove-query" phx-value-index={i} />
      </div>
    <% end  %>
    """
  end

  defp color(type) do
    case type do
      :name -> "text-emerald-800 bg-emerald-100"
      :tag -> "text-indigo-800 bg-indigo-100"
    end
  end
end
