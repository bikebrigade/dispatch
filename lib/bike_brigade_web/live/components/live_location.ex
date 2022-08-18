defmodule BikeBrigadeWeb.Components.LiveLocation do
  use BikeBrigadeWeb, :live_component

  alias Phoenix.LiveView.JS
  alias BikeBrigade.Locations.Location
  alias BikeBrigade.Geocoder

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def update(%{as: as, location: location} = assigns, socket) do
    changeset = Location.changeset(location)
    form = Phoenix.HTML.FormData.to_form(changeset, as: as)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn -> form end)}
  end

  def lookup_location(location, value) do
    params =
      case IO.inspect(Geocoder.lookup(value)) do
        {:ok, location_lookup} -> location_lookup
        _ -> %{}
      end

    Location.changeset(
      location,
      params
    )
  end

  @impl Phoenix.LiveComponent
  def handle_event("geocode", %{"value" => value} = foo, socket) do
    IO.inspect("geocode")

    form =
      socket.assigns.location
      |> lookup_location(value)
      |> Phoenix.HTML.FormData.to_form(as: socket.assigns.as)

    {:noreply,
     socket
     |> assign(:form, form)}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div id={@id} class="my-2">
      <%= hidden_input(@form, :coords, value: dump_coords(@location)) %>

      <div class="text-sm font-medium leading-5 text-gray-700">
        <%= @label %>
      </div>
      <div class="location-locationm-container px-2 py-0.5 -mx-2 my-0.5">
        <div class="flex mt-1">
          <div class="w-full rounded-md shadow-sm">
            <input
              phx-focus={show_edit_mode(@id)}
              phx-keydown="geocode"
              phx-target={@myself}
              type="text"
              value={to_string(@location)}
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
                <%= text_input(@form, :address,
                  required: true,
                  phx_debounce: "blur",
                  autocomplete: "street-address",
                  class:
                    "block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5"
                ) %>
              </div>
              <%= # error_tag(@location, :address) %>
            </div>
            <div class="w-1/4">
              <label class="block text-xs font-medium leading-5 text-gray-700">
                Unit
              </label>
              <div class="mt-1 rounded-md shadow-sm">
                <%= text_input(@form, :unit,
                  phx_debounce: "blur",
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
                <%= text_input(@form, :buzzer,
                  phx_debounce: "blur",
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
                <%= text_input(@form, :postal,
                  required: true,
                  phx_debounce: "blur",
                  class:
                    "block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5"
                ) %>
              </div>
              <%= # error_tag(@location, :postal) %>
            </div>
            <div class="w-1/4">
              <label class="block text-xs font-medium leading-5 text-gray-700">
                City
              </label>
              <div class="mt-1 rounded-md shadow-sm">
                <%= text_input(@form, :city,
                  required: true,
                  phx_debounce: "blur",
                  class:
                    "block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5"
                ) %>
              </div>
              <%= # error_tag(@location, :city) %>
            </div>
            <div class="w-1/4">
              <label class="block text-xs font-medium leading-5 text-gray-700">
                Province
              </label>
              <div class="mt-1 rounded-md shadow-sm">
                <%= text_input(@form, :province,
                  required: true,
                  phx_debounce: "blur",
                  class:
                    "block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5"
                ) %>
              </div>
              <%= # error_tag(@location, :province) %>
            </div>
            <div class="w-1/4">
              <label class="block text-xs font-medium leading-5 text-gray-700">
                Country
              </label>
              <div class="mt-1 rounded-md shadow-sm">
                <%= text_input(@form, :country,
                  required: true,
                  phx_debounce: "blur",
                  class:
                    "block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5"
                ) %>
              </div>
              <%= # error_tag(@location, :country) %>
            </div>
          </div>
          <C.map coords={cast_coords(@location)} class="w-full h-64 mt-2" />
        </div>
      </div>
    </div>
    """
  end

  defp hide_edit_mode(id) do
    JS.hide(to: "##{id} .edit-mode")
    |> JS.remove_class("border-2 border-dashed", to: "##{id} .location-locationm-container")
  end

  defp show_edit_mode(id) do
    JS.show(to: "##{id} .edit-mode")
    |> JS.add_class("border-2 border-dashed", to: "##{id} .location-locationm-container")
  end

  defp dump_coords(location) do
    location.coords |> Geo.JSON.encode!() |> Jason.encode!()
  end

  defp cast_coords(location) do
    location.coords
  end
end
