defmodule BikeBrigadeWeb.Components.LocationForm do
  use BikeBrigadeWeb, :component

  def component(assigns) do
    ~H"""
    <div class="my-2">
      <%= hidden_input(@for, :coords, value: dump_coords(@for)) %>
      <%= hidden_input(@for, :postal) %>
      <%= hidden_input(@for, :city) %>
      <%= hidden_input(@for, :province) %>
      <%= hidden_input(@for, :country) %>
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
              <%= text_input(@for, :address,
                required: true,
                phx_debounce: "blur",
                autocomplete: "street-address",
                class:
                  "block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5"
              ) %>
            </div>
            <%= error_tag(@for, :address) %>
          </div>
          <div class="w-1/4">
            <label class="block text-xs font-medium leading-5 text-gray-700">
              Unit
            </label>
            <div class="mt-1 rounded-md shadow-sm">
              <%= text_input(@for, :unit,
                class:
                  "block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5"
              ) %>
            </div>
          </div>
          <div class="w-1/4">
            <label class="block text-xs font-medium leading-5 text-gray-700">
              Buzzer
            </label>
            <div class="mt-1 rounded-md shadow-sm">
              <%= text_input(@for, :buzzer,
                class:
                  "block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5"
              ) %>
            </div>
          </div>
        </div>
        <C.map coords={cast_coords(@for)} class="w-full h-64 mt-2" />
      </div>
    </div>
    """
  end

  defp dump_coords(form) do
    case input_value(form, :coords) do
      %Geo.Point{} = coords -> coords |> Geo.JSON.encode!() |> Jason.encode!()
      json when is_binary(json) -> json
    end
  end

  defp cast_coords(form) do
    case input_value(form, :coords) do
      %Geo.Point{} = coords -> coords
      json when is_binary(json) -> Jason.decode!(json) |> Geo.JSON.decode!()
    end
  end
end
