defmodule BikeBrigadeWeb.Components.LocationComponent do
  use BikeBrigadeWeb, :live_component

  alias BikeBrigade.Location

  @impl Phoenix.LiveComponent
  def mount(socket) do
    location = %Location{city: "Toronto"}

    socket =
      assign(socket, :location, location)
      |> assign_new(:error, fn -> nil end)

    {:ok, socket}
  end

  def handle_event("fetch-location", %{"value" => address}, socket) do
    location = reset_address(socket.assigns.location, address)

    socket =
      case Location.complete(location) do
        {:ok, complete_location} ->
          assign(socket, :error, nil) |> assign(:location, complete_location)

        {:error, error} ->
          assign(socket, :error, error) |> assign(:location, location)
      end

    {:noreply, socket}
  end

  defp reset_address(location, address) do
    if [_, unit, parsed_address] =
         Regex.run(~r/^\s*(?<unit>[^\s]+)\s*-\s*(?<address>.*)$/, address) do
      %{location | unit: unit, address: parsed_address, postal: nil}
    else
      %{location | address: address, postal: nil}
    end
  end

  # TODO maybe this should be a form instead of these two things
  def handle_event("set-unit", %{"value" => unit}, socket) do
    location =
      socket.assigns.location
      |> Map.put(:unit, unit)

    {:noreply, socket |> assign(:location, location)}
  end

  def handle_event("set-buzzer", %{"value" => buzzer}, socket) do
    location =
      socket.assigns.location
      |> Map.put(:buzzer, buzzer)

    {:noreply, socket |> assign(:location, location)}
  end

  def render(assigns) do
    ~H"""
      <div>
        <div class="flex my-2 space-x-1">
          <div class="w-1/2">
            <label class="block text-sm font-medium leading-5 text-gray-700">
              Address
            </label>
            <div class="mt-1 rounded-md shadow-sm">
              <input value={@location.address} type="text" required="true" phx-blur="fetch-location" phx-target={@myself} class="block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5" />
            </div>
            <%= if @error do %>
              <p class="mt-2 text-sm text-red-600"><%= @error %></p>
            <% end %>
          </div>
          <div class="w-1/2">
            <label class="block text-sm font-medium leading-5 text-gray-700">
              Postal
            </label>
            <div class="mt-1 rounded-md shadow-sm">
              <input value={@location.postal} type="text" disabled="true" class="block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out bg-gray-100 border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5" />
            </div>
          </div>
        </div>
        <div class="flex my-2 space-x-1">
          <div class="w-1/2">
            <label class="block text-sm font-medium leading-5 text-gray-700">
              Unit
            </label>
            <div class="mt-1 rounded-md shadow-sm">
              <input value={@location.unit} type="text" required="true" phx-blur="set-unit" phx-target={@myself} class="block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5" />
            </div>
          </div>
          <div class="w-1/2">
            <label class="block text-sm font-medium leading-5 text-gray-700">
              Buzzer
            </label>
            <div class="mt-1 rounded-md shadow-sm">
              <input value={@location.buzzer} type="text" phx-blur="set-buzzer" phx-target={@myself} class="block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5" />
            </div>
          </div>
        </div>
        <%= if @location.coords do %>
          <div class="w-full h-64 ">
            <leaflet-map phx-hook="LeafletMap" id="location-map" data-lat={ lat(@location.coords) } data-lng={ lng(@location.coords) }
              data-mapbox_access_token="pk.eyJ1IjoibXZleXRzbWFuIiwiYSI6ImNrYWN0eHV5eTBhMTMycXI4bnF1czl2ejgifQ.xGiR6ANmMCZCcfZ0x_Mn4g"
              class="h-full">
              <leaflet-marker phx-hook="LeafletMarker" id={"location-marker"} data-lat={ lat(@location.coords) } data-lng={ lng(@location.coords) }
              data-icon="warehouse" data-color="#1c64f2"></leaflet-marker>
            </leaflet-map>
          </div>
        <% end %>
      </div>
    """
  end
end
