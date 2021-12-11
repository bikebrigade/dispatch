defmodule BikeBrigadeWeb.Components.LocationFormComponent do
  use BikeBrigadeWeb, :live_component

  alias BikeBrigade.Location

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
      <div class="my-2">
        <%= hidden_input @for, :coords, value: Jason.encode!(@location.coords) %>
        <%= hidden_input @for, :neighborhood, value: @location.neighborhood %>
        <%= hidden_input @for, :postal, value: @location.postal %>
        <%= hidden_input @for, :city, value: @location.city %>
        <%= hidden_input @for, :province, value: @location.province %>
        <%= hidden_input @for, :country, value: @location.country %>
        <div class="text-sm font-medium leading-5 text-gray-700">
          <%= render_slot @label %>
        </div>
        <div class="p-2 my-1 border-2 border-dashed">
          <div class="flex space-x-1">
            <div class="w-1/2">
              <label class="block text-xs font-medium leading-5 text-gray-700">
                Address
              </label>
              <div class="mt-1 rounded-md shadow-sm">
                <%= text_input @for, :address, required: true, value: @location.address, phx_target: @myself, phx_debounce: "100", class: "block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5" %>
              </div>
              <%= if @error do %>
                <p class="mt-2 text-xs text-red-600"><%= @error %></p>
              <% end %>
            </div>
            <div class="w-1/4">
              <label class="block text-xs font-medium leading-5 text-gray-700">
                Unit
              </label>
              <div class="mt-1 rounded-md shadow-sm">
              <%= text_input @for, :unit, value: @location.unit, phx_target: @myself, class: "block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5" %>
              </div>
            </div>
            <div class="w-1/4">
              <label class="block text-xs font-medium leading-5 text-gray-700">
                Buzzer
              </label>
              <div class="mt-1 rounded-md shadow-sm">
              <%= text_input @for, :buzzer, value: @location.buzzer, phx_target: @myself, class: "block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5" %>
              </div>
            </div>
          </div>
        <%= if @location.coords do %>
          <div class="w-full h-64 mt-2 ">
            <leaflet-map phx-hook="LeafletMap" id={"location-map-#{inspect(@location.coords.coordinates)}"} data-lat={ lat(@location.coords) } data-lng={ lng(@location.coords) }
              data-mapbox_access_token="pk.eyJ1IjoibXZleXRzbWFuIiwiYSI6ImNrYWN0eHV5eTBhMTMycXI4bnF1czl2ejgifQ.xGiR6ANmMCZCcfZ0x_Mn4g"
              class="h-full">
              <leaflet-marker phx-hook="LeafletMarker" id={"location-marker-#{inspect(@location.coords.coordinates)}"} data-lat={ lat(@location.coords) } data-lng={ lng(@location.coords) }
              data-icon="warehouse" data-color="#1c64f2"></leaflet-marker>
            </leaflet-map>
          </div>
        <% end %>
      </div>
      </div>
    """
  end

  @impl Phoenix.LiveComponent
  def mount(socket) do
    socket =
      socket
      |> assign(:error, nil)

    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def update(%{location: location} = assigns, socket) do
    socket =
      socket
      |> assign(:error, nil)
      |> maybe_complete_location(location)
      |> assign(Map.delete(assigns, :location))

    {:ok, socket}
  end

  defp maybe_complete_location(socket, location) do
    case socket.assigns do
      %{location: ^location} ->
        # If we haven't changed location, don't complete it
        socket

      %{location: _} ->
        complete_location(socket, location)

      %{} ->
        # If this is the first time loading the component, don't autocomplete
        assign(socket, :location, location)
    end
  end

  def complete_location(socket, location) do
    case Location.complete(%{location | postal: nil}) do
      {:ok, complete_location} ->
        assign(socket, :location, complete_location)

      {:error, error} ->
        assign(socket, :error, error)
    end
  end
end
