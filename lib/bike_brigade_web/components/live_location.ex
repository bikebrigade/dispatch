defmodule BikeBrigadeWeb.Components.LiveLocation do
  use BikeBrigadeWeb, :live_component

  alias Phoenix.LiveView.JS
  alias BikeBrigade.Locations.Location

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
    {:ok,
     socket
     |> assign(:location, %Location{})
     |> assign(:open, false)}
  end

  @impl Phoenix.LiveComponent
  def update(%{field: {f, field}} = assigns, socket) do
    as = input_name(f, field)
    value = input_value(f, field)

    {location, changeset} =
      case value do
        %Location{} = location ->
          {location, Location.changeset(location)}

        %Ecto.Changeset{} = changeset ->
          location = Ecto.Changeset.apply_changes(changeset)
          {location, changeset}

        %{} = map ->
          changeset =
            Location.changeset(
              socket.assigns.location,
              map
            )

          location = Ecto.Changeset.apply_changes(changeset)
          {location, changeset}

        nil ->
          location = %Location{}
          changeset = Location.changeset(location)

          {location, changeset
        }
      end

    form = Phoenix.HTML.FormData.to_form(changeset, as: as)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:as, as)
     |> assign(:location, location)
     |> assign(:form, form)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("change", params, socket) do
    list = FormParams.parse(socket.assigns.as)

    location_params = get_in(params, list)

    {field, value} =
      case location_params do
        %{"address" => address} -> {:address, address}
        %{"postal" => postal} -> {:postal, postal}
        %{"unit" => unit} -> {:unit, unit}
        %{"buzzer" => buzzer} -> {:buzzer, buzzer}
        %{"smart_input" => value} -> {:smart_input, value}
      end

    changeset =
      Location.change_location(socket.assigns.location, field, value)
      |> Map.put(:action, :validate)

    form = Phoenix.HTML.FormData.to_form(changeset, as: socket.assigns.as)

    location = apply_changes(changeset)

    socket =
      if location.coords != socket.assigns.location.coords do
        socket
        |> push_event("leaflet:update_layer", encode_marker(location))
        |> push_event("leaflet:redraw_map", %{recenter: true})
      else
        socket
      end
      |> assign(:location, location)
      |> assign(:form, form)

    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("open", _params, socket) do
    {:noreply,
     socket
     |> assign(:open, true)
     |> push_event("leaflet:redraw_map", %{})}
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
          <div class="relative w-full">
            <div class="rounded-md shadow-sm">
              <input
                id={"#{@id}-location-input-open"}
                name={input_name(@form, :smart_input)}
                phx-focus={JS.push("open", target: @myself)}
                phx-change={JS.push("change", target: @myself)}
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
            <%= error_tag(@form, :location, show_field: false) %>
          </div>
          <button
            type="button"
            class={"#{if !@open, do: "hidden"} ml-1 edit-mode"}
            phx-click={JS.push("close", target: @myself)}
          >
            <Heroicons.chevron_down solid class="w-5 h-5" />
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
              <%= error_tag(@form, :address, show_field: false) %>
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
                  #                  phx_debounce: "1000",
                  phx_target: @myself,
                  class:
                    "block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5"
                ) %>
              </div>
              <%= error_tag(@form, :postal, show_field: false) %>
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
          <.map
            id={"#{@id}-map"}
            coords={@location.coords}
            class="w-full h-64 mt-2"
            initial_layers={[encode_marker(@location)]}
          />
        </div>
      </div>
    </div>
    """
  end

  defp encode_marker(location) do
    %{
      id: location.id,
      type: :marker,
      data: %{
        lat: lat(location),
        lng: lng(location),
        icon: "warehouse",
        color: "#1c64f2"
      }
    }
  end

  defp location_input_value(location) do
    location.address || location.postal
  end

  defp dump_coords(%{coords: nil}) do
    %Geo.Point{} |> Geo.JSON.encode!() |> Jason.encode!()
  end

  defp dump_coords(%{coords: coords}) do
    coords |> Geo.JSON.encode!() |> Jason.encode!()
  end
end
