defmodule BikeBrigadeWeb.Components.RiderSelectionComponent do
  use BikeBrigadeWeb, :live_component

  alias BikeBrigade.Riders

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok,
     socket
     |> assign(:selected_riders, [])
     |> assign(:search, nil)
     |> assign(:riders, [])
     |> assign(:multi, false)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("suggest", %{"value" => search}, socket) do
    {:noreply, assign(socket, :riders, Riders.search_riders(search, 10))}
  end

  def handle_event("unselect", %{"id" => id}, socket) do
    %{selected_riders: selected_riders} = socket.assigns
    id = String.to_integer(id)
    selected_riders = Enum.reject(selected_riders, &(&1.id == id))

    {:noreply,
     socket
     |> assign(:selected_riders, selected_riders)}
  end

  def handle_event("select", %{"id" => id}, socket) do
    %{selected_riders: selected_riders} = socket.assigns

    rider = Riders.get_rider!(id)

    {:noreply,
     socket
     |> assign(:selected_riders, selected_riders ++ [rider])
     |> assign(:riders, [])}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="rider-select">
      <div class="grid grid-cols-2">
        <%= for rider <- @selected_riders do %>
          <.show rider={rider}>
            <:x>
              <a href="#" phx-click="unselect" phx-value-id={ rider.id } phx-target={ @myself }  class="block text-sm text-gray-400 bg-white rounded-md font-base hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                <Heroicons.Outline.x class="w-5 h-5" />
              </a>
            </:x>
          </.show>
          <input type="hidden" name={ @input_name } value={ rider.id }>
        <% end %>
      </div>
    <%= if @multi || Enum.empty?(@selected_riders) do %>
      <input type="text" phx-keyup="suggest" phx-target={ @myself } phx-debounce="50" name="search" placeholder="Type to search for riders by name"
      class="block w-full px-3 py-2 placeholder-gray-400 border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
      <ul id="rider-selection-list" class="overflow-y-auto max-h-64">
        <%= for rider <- @riders do %>
          <li id={"rider-selection:#{rider.id}"}>
            <a href="#" phx-click="select" phx-value-id={ rider.id } phx-target={ @myself } class="block transition duration-150 ease-in-out hover:bg-gray-50 focus:outline-none focus:bg-gray-50">
              <.show rider={rider}/>
            </a>
          </li>
        <% end %>
      </ul>
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
          <img class="w-12 h-12 rounded-full" src={ gravatar(@rider.email) } alt="" />
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
