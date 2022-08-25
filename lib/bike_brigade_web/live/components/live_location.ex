defmodule BikeBrigadeWeb.Components.LiveLocation do
  use BikeBrigadeWeb, :live_component

  alias Phoenix.LiveView.JS
  alias BikeBrigade.Locations.Location
  alias BikeBrigade.Geocoder

  import Ecto.Changeset

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, socket |> assign(:hidden, true)}
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

  def parse_unit(value) do
    case Regex.run(~r/unit[: ]*([0-9]*)/i, value) do
      [_, unit] ->
        unit

      _ ->
        case Regex.run(~r/^\s*(?<unit>[^\s]+)\s*-\s*(?<value>.*)$/, value) do
          [_, unit, _] ->
            unit

          _ ->
            nil
        end
    end
  end

  def parse_buzzer(value) do
    case Regex.run(~r/buzz[: ]*([0-9]*)/i, value) do
      [_, buzzer] ->
        buzzer

      _ ->
        nil
    end
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
        _ -> %{}
      end
      |> Map.put(:unit, parse_unit(value))
      |> Map.put(:buzzer, parse_buzzer(value))

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
  def handle_event("change-field", %{"value" => value, "field" => field}, socket) do
    params = Map.new() |> Map.put(String.to_existing_atom(field), value)

    changeset = socket.assigns.location |> Location.changeset(params)

    form = Phoenix.HTML.FormData.to_form(changeset, as: socket.assigns.as)

    {:noreply, socket |> assign(:location, apply_changes(changeset)) |> assign(:form, form)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("toggle_hidden", _params, socket) do
    {:noreply,
     socket
     |> assign(:hidden, not socket.assigns.hidden)
     |> push_event("redraw-map", %{})}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div id={@id} class="my-2">
      <%= hidden_input(@form, :coords, value: dump_coords(@location)) %>

      <div class="text-sm font-medium leading-5 text-gray-700">
        <%= @label %>
      </div>
      <div class={"#{if not @hidden, do: "border-2 border-dashed"} px-2 py-0.5 -mx-2 my-0.5"}>
        <div class="flex mt-1">
          <div class="w-full rounded-md shadow-sm">
            <input
              id={"#{@id}-location-input"}
              phx-focus={on_focus(@location, @hidden, target: @myself)}
              phx-keyup={JS.push("geocode", target: @myself)}
              type="text"
              value={location_input_value(@location, @hidden)}
              class="block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5"
            />
          </div>
          <button
            type="button"
            class={"#{if @hidden, do: "hidden"} ml-1 edit-mode"}
            phx-click={
              JS.set_attribute({"value", location_input_value(@location, true)},
                to: "##{@id}-location-input"
              )
              |> JS.push("toggle_hidden", target: @myself)
            }
          >
            <Heroicons.Solid.chevron_down class="w-5 h-5" />
          </button>
        </div>
        <div class={"#{if @hidden, do: "hidden"} my-1 edit-mode"}>
          <div class="flex space-x-1">
            <div class="w-1/2">
              <label class="block text-xs font-medium leading-5 text-gray-700">
                Address
              </label>
              <div class="mt-1 rounded-md shadow-sm">
                <input
                  phx-blur="change-field"
                  phx-target={@myself}
                  value={@location.address}
                  phx-value-field={:address}
                  type="text"
                  autocomplete="street-address"
                  class="block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5"
                />
              </div>
              <%= # error_tag(@location, :address) %>
            </div>
            <div class="w-1/4">
              <label class="block text-xs font-medium leading-5 text-gray-700">
                Unit
              </label>
              <div class="mt-1 rounded-md shadow-sm">
                <input
                  phx-blur="change-field"
                  phx-target={@myself}
                  value={@location.unit}
                  phx-value-field={:unit}
                  type="text"
                  class="block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5"
                />
              </div>
            </div>
            <div class="w-1/4">
              <label class="block text-xs font-medium leading-5 text-gray-700">
                Buzzer
              </label>
              <div class="mt-1 rounded-md shadow-sm">
                <input
                  phx-blur="change-field"
                  phx-target={@myself}
                  value={@location.buzzer}
                  phx-value-field={:buzzer}
                  type="text"
                  class="block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5"
                />
              </div>
            </div>
          </div>
          <div class="flex mt-2 space-x-1">
            <div class="w-1/4">
              <label class="block text-xs font-medium leading-5 text-gray-700">
                Postal Code
              </label>
              <div class="mt-1 rounded-md shadow-sm">
                <input
                  phx-blur="change-field"
                  phx-target={@myself}
                  value={@location.postal}
                  phx-value-field={:postal}
                  required="true"
                  type="text"
                  class="block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5"
                />
              </div>
              <%= # error_tag(@location, :postal) %>
            </div>
            <div class="w-1/4">
              <label class="block text-xs font-medium leading-5 text-gray-700">
                City
              </label>
              <div class="mt-1 rounded-md shadow-sm">
                <input
                  phx-blur="change-field"
                  phx-target={@myself}
                  value={@location.city}
                  phx-value-field={:city}
                  type="text"
                  class="block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5"
                />
              </div>
              <%= # error_tag(@location, :city) %>
            </div>
            <div class="w-1/4">
              <label class="block text-xs font-medium leading-5 text-gray-700">
                Province
              </label>
              <div class="mt-1 rounded-md shadow-sm">
                <input
                  phx-blur="change-field"
                  phx-target={@myself}
                  value={@location.province}
                  phx-value-field={:province}
                  type="text"
                  class="block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5"
                />
              </div>
              <%= # error_tag(@location, :province) %>
            </div>
            <div class="w-1/4">
              <label class="block text-xs font-medium leading-5 text-gray-700">
                Country
              </label>
              <div class="mt-1 rounded-md shadow-sm">
                <input
                  phx-blur="change-field"
                  phx-target={@myself}
                  value={@location.country}
                  phx-value-field={:country}
                  type="text"
                  class="block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5"
                />
              </div>
              <%= # error_tag(@location, :country) %>
            </div>
          </div>
          <C.map_next
            coords={cast_coords(@location)}
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

  defp on_focus(location, hidden, opts \\ []) do
    if hidden do
      JS.set_attribute({"value", location_input_value(location, false)})
      |> JS.push("toggle_hidden", opts)
    end
  end

  defp location_input_value(location, hidden) do
    if hidden do
      to_string(location)
    else
      case location.address do
        nil -> location.postal
        _ -> location.address
      end
    end
  end

  defp dump_coords(location) do
    location.coords |> Geo.JSON.encode!() |> Jason.encode!()
  end

  defp cast_coords(location) do
    location.coords
  end
end
