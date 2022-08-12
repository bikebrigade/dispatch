defmodule BikeBrigadeWeb.Components.LocationForm do
  use BikeBrigadeWeb, :phoenix_component

  alias Phoenix.LiveView.JS

  def component(assigns) do
    # TODO have the parent assign us an id
    assigns = assign(assigns, :id, "location-form")

    ~H"""
    <div id={@id} class="my-2">
      <%= hidden_input(@for, :coords, value: dump_coords(@for)) %>
      <div class="text-sm font-medium leading-5 text-gray-700">
        <%= @label %>
      </div>
      <div class="location-form-container px-2 py-0.5 -mx-2 my-0.5">
        <div class="flex mt-1">
          <div class="w-full rounded-md shadow-sm">
            <input
              phx-focus={show_edit_mode(@id)}
              type="text"
              class="block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5"
            />
          </div>
          <button type="button" class="hidden ml-1 edit-mode" phx-click={hide_edit_mode(@id)}>
            <Heroicons.Solid.chevron_down class="w-5 h-5" />
          </button>
        </div>
        <div class="hidden my-1 edit-mode">
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
          <div class="flex mt-2 space-x-1">
            <div class="w-1/4">
              <label class="block text-xs font-medium leading-5 text-gray-700">
                Postal Code
              </label>
              <div class="mt-1 rounded-md shadow-sm">
                <%= text_input(@for, :postal,
                  required: true,
                  class:
                    "block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5"
                ) %>
              </div>
              <%= error_tag(@for, :postal) %>
            </div>
            <div class="w-1/4">
              <label class="block text-xs font-medium leading-5 text-gray-700">
                City
              </label>
              <div class="mt-1 rounded-md shadow-sm">
                <%= text_input(@for, :city,
                  required: true,
                  class:
                    "block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5"
                ) %>
              </div>
              <%= error_tag(@for, :city) %>
            </div>
            <div class="w-1/4">
              <label class="block text-xs font-medium leading-5 text-gray-700">
                Province
              </label>
              <div class="mt-1 rounded-md shadow-sm">
                <%= text_input(@for, :province,
                  required: true,
                  class:
                    "block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5"
                ) %>
              </div>
              <%= error_tag(@for, :province) %>
            </div>
            <div class="w-1/4">
              <label class="block text-xs font-medium leading-5 text-gray-700">
                Country
              </label>
              <div class="mt-1 rounded-md shadow-sm">
                <%= text_input(@for, :country,
                  required: true,
                  class:
                    "block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5"
                ) %>
              </div>
              <%= error_tag(@for, :country) %>
            </div>
          </div>
          <C.map coords={cast_coords(@for)} class="w-full h-64 mt-2" />
        </div>
      </div>
    </div>
    """
  end

  defp hide_edit_mode(id) do
    JS.hide(to: "##{id} .edit-mode")
    |> JS.remove_class("border-2 border-dashed", to: "##{id} .location-form-container")
  end

  defp show_edit_mode(id) do
    JS.show(to: "##{id} .edit-mode")
    |> JS.add_class("border-2 border-dashed", to: "##{id} .location-form-container")
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
