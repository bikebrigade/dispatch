defmodule BikeBrigadeWeb.Components.LiveLocation do
  use BikeBrigadeWeb, :live_component

  alias Phoenix.LiveView.JS
  alias BikeBrigade.Locations.Location
  alias BikeBrigade.Geocoder

  import Ecto.Changeset

  defmodule FormParams do
    @moduledoc """
    Parse the form name in the format "foo[bar][baz]" into ["foo", "bar", "baz"]
    """
    import NimbleParsec

    defparsecp(
      :form_parser,
      ascii_string([{:not, ?[}, {:not, ?]}], min: 1)
      |> repeat(
        ignore(string("["))
        |> concat(ascii_string([{:not, ?[}, {:not, ?]}], min: 1))
        |> ignore(string("]"))
      )
    )

    def parse(name) do
      {_, list, _, _, _, _} = form_parser(name)
      list
    end
  end

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, socket |> assign(:open, false)}
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

  def parse_postal_code(value) do
    case Regex.run(~r/^\W*([a-z]\d[a-z])\s*(\d[a-z]\d)\W*$/i, value) do
      [_, left, right] ->
        String.upcase("#{left} #{right}")

      _ ->
        value
    end
  end

  def lookup_location(location, value) do
    params =
      case value |> parse_postal_code() |> Geocoder.lookup() do
        {:ok, location_lookup} -> location_lookup
        _ -> Map.new()
      end
      |> Map.put(:unit, nil)
      |> Map.put(:buzzer, nil)

    Location.changeset(
      location,
      params
    )
  end

  @impl Phoenix.LiveComponent
  def handle_event("geocode", %{"value" => value}, socket) do
    changeset = lookup_location(socket.assigns.location, value)
    form = Phoenix.HTML.FormData.to_form(changeset, as: socket.assigns.as)
    {:noreply, socket |> assign(:location, apply_changes(changeset)) |> assign(:form, form)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("change", params, socket) do
    list = FormParams.parse(socket.assigns.as)

    location_params = get_in(params, list)

    changeset =
      case location_params do
        %{"address" => address} ->
          lookup_location(socket.assigns.location, address)

        %{"postal" => postal} ->
          lookup_location(socket.assigns.location, postal)

        _ ->
          Location.changeset(socket.assigns.location, %{})
      end

    form = Phoenix.HTML.FormData.to_form(changeset, as: socket.assigns.as)
    {:noreply, socket |> assign(:location, apply_changes(changeset)) |> assign(:form, form)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("open", _params, socket) do
    {:noreply,
     socket
     |> assign(:open, true)
     |> push_event("redraw-map", %{})}
  end

  @impl Phoenix.LiveComponent
  def handle_event("close", _params, socket) do
    {:noreply,
     socket
     |> assign(:open, false)}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div id={@id} class="my-2">
      <%= hidden_input(@form, :coords, value: dump_coords(@location)) %>

      <div class="text-sm font-medium leading-5 text-gray-700">
        <%= @label %>
      </div>
      <div class={"#{if @open, do: "border-2 border-dashed"} px-2 py-0.5 -mx-2 my-0.5"}>
        <div class="flex mt-1">
          <div class="relative w-full rounded-md shadow-sm">
            <input
              id={"#{@id}-location-input-open"}
              phx-focus={JS.push("open", target: @myself)}
              phx-keyup={JS.push("geocode", target: @myself)}
              type="text"
              value={location_input_value(@location)}
              class="block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5"
            />
            <input
              disabled
              id={"#{@id}-location-input-closed"}
              type="text"
              value={@location}
              class={
                "#{if @open, do: "hidden"} pointer-events-none absolute top-0 left-0 block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5"
              }
            />
          </div>
          <button
            type="button"
            class={"#{if !@open, do: "hidden"} ml-1 edit-mode"}
            phx-click={JS.push("close", target: @myself)}
          >
            <Heroicons.Solid.chevron_down class="w-5 h-5" />
          </button>
        </div>
        <div class={"#{if !@open, do: "hidden"} my-1 edit-mode"}>
          <div class="flex space-x-1">
            <div class="w-1/2">
              <label class="block text-xs font-medium leading-5 text-gray-700">
                Address
              </label>
              <div class="mt-1 rounded-md shadow-sm">
                <%= text_input(@form, :address,
                  phx_change: "change",
                  phx_target: @myself,
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
                  phx_change: "change",
                  phx_target: @myself,
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
                  phx_change: "change",
                  phx_target: @myself,
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
                  phx_change: "change",
                  phx_target: @myself,
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
                  disabled: true,
                  phx_change: "change",
                  phx_target: @myself,
                  class:
                    "disabled:border-gray-200 disabled:bg-gray-50 disabled:text-gray-500 block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5"
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
                  disabled: true,
                  phx_change: "change",
                  phx_target: @myself,
                  class:
                    " disabled:border-gray-200 disabled:bg-gray-50 disabled:text-gray-500 block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5"
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
                  disabled: true,
                  phx_change: "change",
                  phx_target: @myself,
                  class:
                    "disabled:border-gray-200 disabled:bg-gray-50 disabled:text-gray-500 block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5"
                ) %>
              </div>
              <%= # error_tag(@location, :country) %>
            </div>
          </div>
          <C.map_next
            coords={@location.coords}
            class="w-full h-64 mt-2"
            initial_markers={encode_marker(@location)}
          />
        </div>
      </div>
    </div>
    """
  end

  defp encode_marker(location) do
    [
      %{
        id: location.id,
        lat: lat(location),
        lng: lng(location),
        icon: "warehouse",
        color: "#1c64f2"
      }
    ]
    |> Jason.encode!()
  end

  defp location_input_value(location) do
    location.address || location.postal
  end

  defp dump_coords(location) do
    location.coords |> Geo.JSON.encode!() |> Jason.encode!()
  end
end
