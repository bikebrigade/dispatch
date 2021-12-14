defmodule BikeBrigadeWeb.Components.LocationForm do
  use BikeBrigadeWeb, :phoenix_component

  def component(assigns) do
    ~H"""
    <div class="my-2">
      <%= hidden_input @for, :coords, value: Jason.encode!(input_value(@for, :coords))  %>
      <%= hidden_input @for, :neighborhood %>
      <%= hidden_input @for, :postal %>
      <%= hidden_input @for, :city  %>
      <%= hidden_input @for, :province %>
      <%= hidden_input @for, :country %>
      <div class="text-sm font-medium leading-5 text-gray-700">
        <%= @label %>
      </div>
      <div class="p-2 my-1 border-2 border-dashed">
        <div class="flex space-x-1">
          <div class="w-1/2">
            <label class="block text-xs font-medium leading-5 text-gray-700">
              Address
            </label>
            <div class="mt-1 rounded-md shadow-sm">
              <%= text_input @for, :address, required: true, phx_debounce: "blur", class: "block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5" %>
            </div>
            <%= error_tag @for, :address %>
          </div>
          <div class="w-1/4">
            <label class="block text-xs font-medium leading-5 text-gray-700">
              Unit
            </label>
            <div class="mt-1 rounded-md shadow-sm">
            <%= text_input @for, :unit, class: "block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5" %>
            </div>
          </div>
          <div class="w-1/4">
            <label class="block text-xs font-medium leading-5 text-gray-700">
              Buzzer
            </label>
            <div class="mt-1 rounded-md shadow-sm">
            <%= text_input @for, :buzzer, class: "block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5" %>
            </div>
          </div>
        </div>
        <.map coords={input_value(@for, :coords)} />
      </div>
    </div>
    """
  end

  defp map(assigns) do
    ~H"""
    <%= if @coords != %Geo.Point{} do %>
      <div class="w-full h-64 mt-2 ">
        <leaflet-map phx-hook="LeafletMap" id={"location-map-#{inspect(@coords.coordinates)}"} data-lat={ lat(@coords) } data-lng={ lng(@coords) }
          data-mapbox_access_token="pk.eyJ1IjoibXZleXRzbWFuIiwiYSI6ImNrYWN0eHV5eTBhMTMycXI4bnF1czl2ejgifQ.xGiR6ANmMCZCcfZ0x_Mn4g"
          class="h-full">
          <leaflet-marker phx-hook="LeafletMarker" id={"location-marker-#{inspect(@coords.coordinates)}"} data-lat={ lat(@coords) } data-lng={ lng(@coords) }
          data-icon="warehouse" data-color="#1c64f2"></leaflet-marker>
        </leaflet-map>
      </div>
    <% end %>
  """
  end
end
