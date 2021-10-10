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
    <div class="">
    <%= for rider <- @selected_riders do %>
      <div class="flex px-3 py-4">
        <div class="flex items-center flex-1 min-w-0">
          <div class="flex-shrink-0">
            <img class="w-12 h-12 rounded-full" src={ gravatar(rider.email) } alt="" />
          </div>
          <div class="ml-2">
            <div class="text-sm font-medium leading-5 text-indigo-600">
              <span><%= rider.name %></span>
              <span class="ml-1 font-normal text-gray-500">
                <%= rider.pronouns %>
              </span>
            </div>
            <div class="flex items-center mt-2 text-sm leading-5 text-gray-500">
              <svg class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" viewBox="0 0 20 20" fill="currentColor">
                <path d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"></path>
              </svg>
              <span class="truncate">
                <%= rider.phone %>
              </span>
            </div>
            <div class="flex items-center mt-2 text-sm text-gray-500">
              <!-- Heroicon name: solid/mail -->
              <svg class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                <path d="M2.003 5.884L10 9.882l7.997-3.998A2 2 0 0016 4H4a2 2 0 00-1.997 1.884z" />
                <path d="M18 8.118l-8 4-8-4V14a2 2 0 002 2h12a2 2 0 002-2V8.118z" />
              </svg>
              <span class="truncate"><%= rider.email %></span>
            </div>
          </div>
        </div>
        <div>
          <a href="#" phx-click="unselect" phx-value-id={ rider.id } phx-target={ @myself }  class="block text-sm text-gray-400 bg-white rounded-md font-base hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
            <!-- Heroicon name: outline/x -->
              <svg class="w-5 h-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" aria-hidden="true">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </a>
        </div>
      </div>
      <input type="hidden" name={ @input_name } value={ rider.id }>
    <% end %>
    <%= if @multi || Enum.empty?(@selected_riders) do %>
      <input type="text" phx-keyup="suggest" phx-target={ @myself } phx-debounce="50" name="search" placeholder="Type to search for riders by name"
      class="block w-full px-3 py-2 placeholder-gray-400 border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
      <ul id="rider-selection-list" class="overflow-y-auto max-h-64">
        <%= for rider <- @riders do %>
          <li id={"rider-selection:#{rider.id}"}>
          <a href="#" phx-click="select" phx-value-id={ rider.id } phx-target={ @myself } class="block transition duration-150 ease-in-out hover:bg-gray-50 focus:outline-none focus:bg-gray-50">
            <div class="flex items-center px-3 py-4">
              <div class="flex items-center flex-1 min-w-0">
                <div class="flex-shrink-0">
                  <img class="w-12 h-12 rounded-full" src={ gravatar(rider.email) } alt="" />
                </div>
                <div class="ml-2">
                  <div class="text-sm font-medium leading-5 text-indigo-600">
                    <span><%= rider.name %></span>
                    <span class="ml-1 font-normal text-gray-500">
                      <%= rider.pronouns %>
                    </span>
                  </div>
                  <div class="flex items-center mt-2 text-sm leading-5 text-gray-500">
                    <svg class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" viewBox="0 0 20 20" fill="currentColor">
                      <path d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"></path>
                    </svg>
                    <span class="truncate">
                      <%= rider.phone %>
                    </span>
                  </div>
                  <div class="flex items-center mt-2 text-sm text-gray-500">
                    <!-- Heroicon name: solid/mail -->
                    <svg class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                      <path d="M2.003 5.884L10 9.882l7.997-3.998A2 2 0 0016 4H4a2 2 0 00-1.997 1.884z" />
                      <path d="M18 8.118l-8 4-8-4V14a2 2 0 002 2h12a2 2 0 002-2V8.118z" />
                    </svg>
                    <span class="truncate"><%= rider.email %></span>
                  </div>
                </div>
              </div>
            </div>
          </a>
          </li>
        <% end %>
      </ul>
    <% end %>
    </div>
    """
  end
end
