defmodule BikeBrigadeWeb.Components do
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  alias BikeBrigade.LocalizedDateTime
  alias BikeBrigadeWeb.Components.Icons

  alias BikeBrigade.Locations.Location

  # TODO get rid of livehelpers?
  import BikeBrigadeWeb.LiveHelpers, only: [lat: 1, lng: 1]

  defguardp is_clickable(rest)
            when is_map_key(rest, :href) or is_map_key(rest, :patch) or
                   is_map_key(rest, :navigate) or is_map_key(rest, :"phx-click")

  @doc """
  Renders button

  ## Examples

      <.button patch={~p"/campaigns/new"} class="ml-2">
      <.button type="submit" phx-click={hide_scheduling()} color={:secondary} class="ml-3">
  """
  attr :type, :string

  attr :size, :atom,
    default: :medium,
    values: [:xxsmall, :xsmall, :small, :medium, :large, :xlarge]

  attr :color, :atom,
    default: :primary,
    values: [:primary, :secondary, :white, :green, :red, :lightred, :clear, :black]

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href patch navigate disabled)
  slot(:inner_block, required: true)

  @button_base_classes [
    "inline-flex text-center items-center border border-transparent",
    "font-medium rounded shadow-sm focus:outline-none focus:ring-2 focus:ring-offset-2",
    "disabled:hover:cursor-not-allowed disabled:opacity-25"
  ]

  # TODO I have a button in messaging form component with
  # phx-submit-loading:opacity-25 phx-submit-loading:hover:cursor-not-allowed phx-submit-loading:pointer-events-none
  # Add this as an option (disable-if-loading) if we need it again

  def button(%{type: type} = assigns) when is_binary(type) do
    assigns = assign(assigns, :button_base_classes, @button_base_classes)

    ~H"""
    <button
      type={@type}
      class={@button_base_classes ++ [button_size(@size), button_color(@color), @class]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  def button(assigns) do
    assigns = assign(assigns, :button_base_classes, @button_base_classes)

    ~H"""
    <.link class={@button_base_classes ++ [button_size(@size), button_color(@color), @class]} {@rest}>
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  defp button_size(size) do
    case size do
      :xxsmall -> "p-0"
      :xsmall -> "px-2.5 py-1.5 text-xs"
      :small -> "px-3 py-2 text-sm leading-4"
      :medium -> "px-4 py-2 text-sm"
      :large -> "px-4 py-2 text-base"
      :xlarge -> "px-6 py-3 text-base"
    end
  end

  defp button_color(color) do
    case color do
      :primary ->
        "text-white bg-indigo-600 hover:bg-indigo-700 focus:ring-indigo-500"

      :secondary ->
        "text-indigo-700 bg-indigo-100 hover:bg-indigo-200 focus:ring-indigo-500"

      :white ->
        "border-gray-300 text-gray-700 bg-white hover:bg-gray-50 focus:ring-indigo-500"

      :green ->
        "text-white bg-green-700 focus:ring-green-600 hover:bg-green-800"

      :red ->
        "text-white bg-red-600 hover:bg-red-700 focus:ring-red-500"

      :lightred ->
        "text-red-700 bg-red-100 hover:bg-red-200 focus:ring-2 focus:ring-offset-2 focus:ring-red-500"

      :clear ->
        "text-gray-400 bg-white hover:text-gray-500  focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"

      :black ->
        "border-gray-300 text-white bg-black hover:bg-white hover:text-black"
    end
  end

  @doc ~S"""
  Renders date.

  ## Examples

      <.date date={@date} />
      <.date date={@date} navigate={~p"/campaigns/#{@campaign}"}/>

  """
  attr :date, Date, required: true
  attr :rest, :global, include: ~w(href patch navigate)

  def date(%{rest: rest} = assigns) when is_clickable(rest) do
    ~H"""
    <.link class="inline-flex border border-gray-400 rounded hover:bg-indigo-50" {@rest}>
      <.date_inner date={@date} />
    </.link>
    """
  end

  def date(assigns) do
    ~H"""
    <div class="inline-flex border border-gray-400 rounded" {@rest}>
      <.date_inner date={@date} />
    </div>
    """
  end

  defp date_inner(assigns) do
    assigns = assign(assigns, :today, LocalizedDateTime.today())

    ~H"""
    <time datetime={@date} class="inline-flex items-center p-1 text-center">
      <span class="mr-1 text-sm font-semibold text-gray-500">
        <%= Calendar.strftime(@date, "%a") %>
      </span>
      <span class="mr-1 text-sm font-bold text-gray-600">
        <%= Calendar.strftime(@date, "%d") %>
      </span>
      <span class="text-sm font-semibold">
        <%= Calendar.strftime(@date, "%b") %>
      </span>
      <%= if @date == @today do %>
        <Icons.circle class="w-2 h-2 ml-1 text-indigo-400" />
      <% end %>
      <%= if @date.year != @today.year do %>
        <span class="ml-1 text-sm font-semibold">
          <%= Calendar.strftime(@date, "%y") %>
        </span>
      <% end %>
    </time>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, default: "flash", doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :rest, :global
  attr :kind, :atom, doc: "one of :info, :error used for styling and flash lookup"
  attr :autoshow, :boolean, default: true, doc: "wether to auto show the flash on mount"
  attr :close, :boolean, default: true, doc: "whether the flash can be closed"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-mounted={@autoshow && show("##{@id}")}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("#flash")}
      class={[
        "fixed hidden top-2 right-2 w-96 z-50 rounded-lg p-3 shadow-md shadow-zinc-900/5 ring-1",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
        @kind == :error && "bg-rose-50 p-3 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
      ]}
      {@rest}
    >
      <button :if={@close} type="button" class="absolute p-2 group top-2 right-1" aria-label="Close">
        <Heroicons.x_mark solid class="w-5 h-5 stroke-current opacity-40 group-hover:opacity-70" />
      </button>
      <p :if={@title} class="flex items-center gap-1.5 text-[0.8125rem] font-semibold leading-6">
        <Heroicons.information_circle :if={@kind == :info} mini class="w-4 h-4" />
        <Heroicons.exclamation_circle :if={@kind == :error} mini class="w-4 h-4" />
        <%= @title %>
      </p>
      <p class="mt-2 text-[0.8125rem] leading-5"><%= msg %></p>
    </div>
    """
  end

  @doc """
  Renders a button for filtering

  ## Examples
      <.filter_button
        phx-click={JS.push("filter_riders", value: %{capacity: :all})}
        selected={@riders_query[:capacity] == "all"}
      >
  """

  attr :selected, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global

  def filter_button(assigns) do
    ~H"""
    <button
      type="button"
      class={[
        "px-3 justify-center h-6 text-gray-800 bg-opacity-50",
        "border-2 border-gray-400 border-solid rounded-full hover:border-gray-600",
        if(@selected, do: "bg-gray-400"),
        @class
      ]}
      {@rest}
    >
      <div class="text-xs leading-relaxed text-center">
        <%= render_slot(@inner_block) %>
      </div>
    </button>
    """
  end

  @doc """
  Renders a location

  ## Examples

      <.location location={@location} />
  """

  attr :location, Location

  def location(assigns) do
    ~H"""
    <div class="inline-flex flex-shrink-0 leading-normal">
      <Heroicons.map_pin mini aria-label="Location" class="w-4 h-4 mt-1 mr-1 text-gray-500" />
      <div class="grid grid-cols-2 gap-y-0 gap-x-1">
        <div class="col-span-2"><%= @location.address %></div>
        <%= if @location.unit do %>
          <div class="text-sm"><span class="font-bold">Unit:</span> <%= @location.unit %></div>
        <% end %>
        <%= if @location.buzzer do %>
          <div class="text-sm"><span class="font-bold">Buzz:</span> <%= @location.buzzer %></div>
        <% end %>
      </div>
    </div>
    """
  end

  @doc """

  Renders a map.

  ## Examples

      <.map_next
        id="rider-map"
        coords={coords(@rider.location)}
        initial_markers={[rider_marker(@rider)]}
        class="w-full h-32 sm:h-40"
      />
  """
  attr :id, :string, required: true
  attr :class, :string, default: "h-full"
  attr :initial_markers, :list, default: []
  attr :coords, Geo.Point, required: true
  attr :lat, :float
  attr :lng, :float

  def map_next(assigns) do
    ~H"""
    <div :if={@coords != %Geo.Point{}} class={@class}>
      <leaflet-map
        phx-hook="LeafletMapNext"
        id={@id}
        data-lat={lat(@coords)}
        data-lng={lng(@coords)}
        data-mapbox_access_token="pk.eyJ1IjoibXZleXRzbWFuIiwiYSI6ImNrYWN0eHV5eTBhMTMycXI4bnF1czl2ejgifQ.xGiR6ANmMCZCcfZ0x_Mn4g"
        data-initial_markers={Jason.encode!(@initial_markers)}
        class="h-full"
      >
      </leaflet-map>
    </div>
    """
  end

  @doc """
  Renders a link used for sorting (with the correct icon)

  ## Examples
      <.sort_link
        phx-click="sort"
        current_field={:program_lead}
        default_order={:asc}
        sort_field={@sort_field}
        sort_order={@sort_order}
        class="pl-2"
      />
  """
  attr :current_field, :atom, required: true
  attr :default_order, :atom, values: [:asc, :desc], default: :asc
  attr :sort_field, :atom, required: true
  attr :sort_order, :atom, values: [:asc, :desc], required: true
  attr :rest, :global

  def sort_link(assigns) do
    selected = assigns.sort_field == assigns.current_field

    assigns =
      assigns
      |> assign(
        :order,
        if(selected, do: next_sort_order(assigns.sort_order), else: assigns.default_order)
      )
      |> assign(:icon_class, [
        "w-5 h-5 hover:text-gray-700",
        if(selected, do: "text-gray-500", else: "text-gray-300")
      ])

    ~H"""
    <button type="button" phx-value-field={@current_field} phx-value-order={@order} {@rest}>
      <%= if @order == :asc do %>
        <Heroicons.bars_arrow_up mini class={@icon_class} />
      <% else %>
        <Heroicons.bars_arrow_down mini class={@icon_class} />
      <% end %>
    </button>
    """
  end

  defp next_sort_order(:asc), do: :desc
  defp next_sort_order(:desc), do: :asc

  @doc """
  Wraps the content with a hoverable tooltip.

  ## Examples
      <.with_tooltip>
        <Heroicons.question_mark_circle solid class="w-4 h-4 ml-0.5 " />
        <:tooltip>
          <div class="w-40">
            Messages over 1600 characters in length tend to get broken up into multiple texts.
          </div>
        </:tooltip>
      </.with_tooltip>
  """
  slot :tooltip, required: true

  def with_tooltip(assigns) do
    ~H"""
    <div class="relative flex flex-col items-center has-tooltip">
      <%= render_slot(@inner_block) %>
      <div class="absolute bottom-0 flex-col items-center mb-6 tooltip">
        <span class="relative z-10 p-2 text-xs leading-none text-white whitespace-no-wrap bg-black rounded-sm shadow-lg">
          <%= render_slot(@tooltip) %>
        </span>
        <div class="w-3 h-3 -mt-2 transform rotate-45 bg-black"></div>
      </div>
    </div>
    """
  end

  # --- OLD ---

  # TODO finish the LeafletNext refactor so we can get rid of this
  def map(assigns) do
    assigns = assign_new(assigns, :class, fn -> "" end)

    ~H"""
    <div class={@class}>
      <%= if @coords != %Geo.Point{} do %>
        <leaflet-map
          phx-hook="LeafletMap"
          id={"location-map-#{inspect(@coords.coordinates)}"}
          data-lat={lat(@coords)}
          data-lng={lng(@coords)}
          data-mapbox_access_token="pk.eyJ1IjoibXZleXRzbWFuIiwiYSI6ImNrYWN0eHV5eTBhMTMycXI4bnF1czl2ejgifQ.xGiR6ANmMCZCcfZ0x_Mn4g"
          class="h-full"
        >
          <leaflet-marker
            phx-hook="LeafletMarker"
            id={"location-marker-#{inspect(@coords.coordinates)}"}
            data-lat={lat(@coords)}
            data-lng={lng(@coords)}
            data-icon="warehouse"
            data-color="#1c64f2"
          >
          </leaflet-marker>
        </leaflet-map>
      <% else %>
        <div class="p-2">Location Unknown</div>
      <% end %>
    </div>
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.focus_first(to: "##{id}-container")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.pop_focus()
  end
end
