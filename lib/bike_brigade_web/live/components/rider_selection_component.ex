defmodule BikeBrigadeWeb.Components.RiderSelectionComponent do
  use BikeBrigadeWeb, :live_component

  alias BikeBrigade.Riders
  alias BikeBrigade.Riders.RiderSearch
  alias BikeBrigade.Riders.RiderSearch.Filter

  @impl Phoenix.LiveComponent
  def mount(socket) do
    # We're going to use a map instead of a MapSet for riders
    # because we want the identity of each eider to be the id

    selected_riders = %{}

    {:ok,
     socket
     |> assign(:selected_riders, selected_riders)
     |> assign(:search, "")
     |> assign(:rider_search, RiderSearch.new(limit: 10))
     |> assign(:search_results, %RiderSearch.Results{})
     |> assign(:riders, [])
     |> assign(:multi, false)}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    assigns =
      case assigns do
        %{selected_riders: selected_riders} when is_list(selected_riders) ->
          Map.put(assigns, :selected_riders, Map.new(selected_riders, fn r -> {r.id, r} end))

        assigns ->
          assigns
      end

    {:ok, assign(socket, assigns)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("suggest", %{"value" => search}, socket) do
    {:noreply,
     socket
     |> assign(:search, search)
     |> update(
       :rider_search,
       &RiderSearch.filter(&1, [%Filter{type: :name_or_phone, search: search}])
     )
     |> fetch_results()}
  end

  def handle_event("unselect", %{"id" => id}, socket) do
    id = String.to_integer(id)

    {:noreply,
     socket
     |> update(:selected_riders, &Map.delete(&1, id))}
  end

  def handle_event("select", %{"id" => id}, socket) do
    {:noreply,
     socket
     |> update(:selected_riders, &Map.put_new_lazy(&1, id, fn -> Riders.get_rider!(id) end))
     |> assign(:search, "")}
  end



  def handle_event("load_more", _values,%{ assigns: assigns } = socket) do
    %{ rider_search: rider_search, riders: riders } = assigns
    next_page_rs= RiderSearch.next_page(rider_search)
    {rider_search, search_results} = RiderSearch.fetch(next_page_rs)
     {:noreply,
     socket
     |> assign(:riders, riders ++ search_results.page )
     |> assign(:rider_search, rider_search)
     }
  end

  defp fetch_results(socket) do
    {rider_search, search_results} =
      RiderSearch.fetch(socket.assigns.rider_search, socket.assigns.search_results)

    socket
    |> assign(:rider_search, rider_search)
    |> assign(:riders, search_results.page)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="rider-select">
      <div class="grid grid-cols-2 overflow-y-auto max-h-64">
        <%= for {id, rider} <- @selected_riders do %>
          <.show rider={rider}>
            <:x>
              <a
                href="#"
                phx-click="unselect"
                phx-value-id={id}
                phx-target={@myself}
                class="block text-sm text-gray-400 bg-white rounded-md font-base hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                <Heroicons.Outline.x class="w-5 h-5" />
              </a>
            </:x>
          </.show>
          <input type="hidden" name={@input_name} value={id} />
        <% end %>
      </div>
      <%= if @multi || Enum.empty?(@selected_riders) do %>
        <input
          type="text"
          phx-keyup="suggest"
          phx-target={@myself}
          phx-debounce="50"
          name="search"
          placeholder="Type to search for riders by name"
          class="block w-full px-3 py-2 placeholder-gray-400 border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
        />
        <%= if @search != "" do %>
          <ul id="rider-selection-list" class="overflow-y-auto max-h-64" phx-hook="RiderSelectionList">
            <%= for rider <- @riders do %>
              <li id={"rider-selection:#{rider.id}"}>
                <a
                  href="#"
                  phx-click="select"
                  phx-value-id={rider.id}
                  phx-target={@myself}
                  class="block transition duration-150 ease-in-out hover:bg-gray-50 focus:outline-none focus:bg-gray-50"
                >
                  <.show rider={rider} />
                </a>
              </li>
            <% end %>
          </ul>
        <% end %>
      <% end %>
    </div>
    """
  end

  defp show(assigns) do
    assigns =
      assigns
      |> assign_new(:x, fn -> [] end)

    ~H"""
    <div class="flex items-start px-3 py-4">
      <div class="flex items-center flex-1 min-w-0">
        <div class="flex-shrink-0">
          <img class="w-12 h-12 rounded-full" src={gravatar(@rider.email)} alt="" />
        </div>
        <div class="ml-2">
          <div class="text-sm font-medium leading-5 text-indigo-600">
            <span><%= @rider.name %></span>
            <span class="ml-1 text-xs font-normal text-gray-500">
              <%= @rider.pronouns %>
            </span>
          </div>
          <div class="flex items-center mt-2 text-xs leading-5 text-gray-500">
            <Heroicons.Solid.phone class="flex-shrink-0 w-4 h-4 mr-1 text-gray-400" />
            <span class="truncate">
              <%= @rider.phone %>
            </span>
          </div>
          <div class="flex items-center mt-2 text-xs text-gray-500">
            <Heroicons.Solid.mail class="flex-shrink-0 w-4 h-4 mr-1 text-gray-400" />
            <span class="truncate"><%= @rider.email %></span>
          </div>
        </div>
      </div>
      <%= render_slot(@x) %>
    </div>
    """
  end
end
