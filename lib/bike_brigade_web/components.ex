defmodule BikeBrigadeWeb.Components do
  use BikeBrigadeWeb, :phoenix_component

  use Phoenix.HTML

  alias BikeBrigade.LocalizedDateTime
  alias BikeBrigadeWeb.Components.Icons

  def date(assigns) do
    date =
      case assigns.date do
        %Date{} = date -> date
        %DateTime{} = datetime -> LocalizedDateTime.to_date(datetime)
      end

    assigns =
      assigns
      |> assign(:date, date)
      |> assign(:today, LocalizedDateTime.today())
      |> assign_new(:link_to, fn -> nil end)

    ~H"""
    <%= if @link_to do %>
      <%= live_patch to: @link_to, class: "hover:bg-gray-50" do %>
        <.date_inner {assigns} />
      <% end %>
    <% else %>
      <.date_inner {assigns} />
    <% end %>
    """
  end

  def date_inner(assigns) do
    ~H"""
    <time
      datetime={@date}
      class="inline-flex items-center p-1 text-center border border-gray-400 rounded"
    >
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

  def button(%{patch_to: patch_to} = assigns) do
    assigns =
      assigns
      |> assign_new(:patch_replace, fn -> false end)

    ~H"""
    <%= live_patch to: patch_to, replace: @patch_replace, class: button_class(assigns) do %>
      <%= render_slot(@inner_block) %>
    <% end %>
    """
  end

  def button(%{redirect_to: redirect_to} = assigns) do
    assigns =
      assigns
      |> assign_new(:patch_replace, fn -> false end)

    ~H"""
    <%= live_redirect to: redirect_to, replace: @patch_replace, class: button_class(assigns) do %>
      <%= render_slot(@inner_block) %>
    <% end %>
    """
  end

  def button(%{href: _href} = assigns) do
    assigns =
      assigns
      |> assign(:class, button_class(assigns))
      |> assign(:attrs, assigns_to_attributes(assigns, [:size, :color]))

    ~H"""
    <a href={@href} class={@class} {@attrs}>
      <%= render_slot(@inner_block) %>
    </a>
    """
  end

  def button(assigns) do
    assigns =
      assigns
      |> assign(:class, button_class(assigns))
      |> assign_new(:type, fn -> "button" end)
      |> assign(:attrs, assigns_to_attributes(assigns, [:size, :color]))

    ~H"""
    <button class={@class} type={@type} {@attrs}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  defp button_class(assigns) do
    size = assigns[:size] || :medium
    color = assigns[:color] || :primary

    base_class =
      "inline-flex text-center items-center border border-transparent font-medium rounded shadow-sm focus:outline-none focus:ring-2 focus:ring-offset-2"

    base_class =
      if assigns[:class] do
        assigns[:class] <> " " <> base_class
      else
        base_class
      end

    size_class =
      case size do
        :xxsmall -> "p-0"
        :xsmall -> "px-2.5 py-1.5 text-xs"
        :small -> "px-3 py-2 text-sm leading-4"
        :medium -> "px-4 py-2 text-sm"
        :large -> "px-4 py-2 text-base"
        :xlarge -> "px-6 py-3 text-base"
      end

    color_class =
      case color do
        :primary ->
          "text-white bg-indigo-600 hover:bg-indigo-700 focus:ring-indigo-500 disabled:hover:cursor-not-allowed"

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

    base_class <> " " <> size_class <> " " <> color_class
  end

  def filter_button(assigns) do
    base_class =
      "px-3 justify-center h-6 text-gray-800 bg-opacity-50 border-2 border-gray-400 border-solid rounded-full hover:border-gray-600"

    class =
      if assigns[:selected] do
        base_class <> " " <> "bg-gray-400"
      else
        base_class
      end

    assigns =
      assigns
      |> assign(:class, class)
      |> assign(:attrs, assigns_to_attributes(assigns, [:selected]))

    ~H"""
    <button type="button" class={@class} {@attrs}>
      <div class="text-xs leading-relaxed text-center">
        <%= render_slot(@inner_block) %>
      </div>
    </button>
    """
  end

  def tooltip(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "" end)

    ~H"""
    <div class="relative flex flex-col items-center has-tooltip">
      <%= render_slot(@inner_block) %>
      <div class={"absolute bottom-0 flex-col items-center mb-6 tooltip #{@class}"}>
        <span class="relative z-10 p-2 text-xs leading-none text-white whitespace-no-wrap bg-black rounded-sm shadow-lg">
          <%= @tooltip %>
        </span>
        <div class="w-3 h-3 -mt-2 transform rotate-45 bg-black"></div>
      </div>
    </div>
    """
  end

  def flash_component(assigns) do
    ~H"""
    <%= if live_flash(@flash, :info) do %>
      <div class="p-4 rounded-md bg-green-50">
        <div class="flex">
          <div class="flex-shrink-0">
            <svg class="w-5 h-5 text-green-400" fill="currentColor" viewBox="0 0 20 20">
              <path
                fill-rule="evenodd"
                d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                clip-rule="evenodd"
              />
            </svg>
          </div>
          <div class="ml-3">
            <p class="text-sm font-medium leading-5 text-green-800">
              <%= live_flash(@flash, :info) %>
            </p>
          </div>
          <div class="pl-3 ml-auto">
            <div class="-mx-1.5 -my-1.5">
              <button
                phx-click="lv:clear-flash"
                phx-value-key="info"
                class="inline-flex rounded-md p-1.5 text-green-500 hover:bg-green-100 focus:outline-none focus:bg-green-100 transition ease-in-out duration-150"
              >
                <svg class="w-5 h-5" viewBox="0 0 20 20" fill="currentColor">
                  <path
                    fill-rule="evenodd"
                    d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
                    clip-rule="evenodd"
                  />
                </svg>
              </button>
            </div>
          </div>
        </div>
      </div>
    <% end %>

    <%= if live_flash(@flash, :error) do %>
      <div class="p-4 rounded-md bg-red-50">
        <div class="flex">
          <div class="flex-shrink-0">
            <svg class="w-5 h-5 text-red-400" fill="currentColor" viewBox="0 0 20 20">
              <path
                fill-rule="evenodd"
                d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
                clip-rule="evenodd"
              />
            </svg>
          </div>
          <div class="ml-3">
            <p class="text-sm font-medium leading-5 text-red-800">
              <%= live_flash(@flash, :error) %>
            </p>
          </div>
          <div class="pl-3 ml-auto">
            <div class="-mx-1.5 -my-1.5">
              <button
                phx-click="lv:clear-flash"
                phx-value-key="error"
                class="inline-flex rounded-md p-1.5 text-red-500 hover:bg-red-100 focus:outline-none focus:bg-red-100 transition ease-in-out duration-150"
              >
                <svg class="w-5 h-5" viewBox="0 0 20 20" fill="currentColor">
                  <path
                    fill-rule="evenodd"
                    d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
                    clip-rule="evenodd"
                  />
                </svg>
              </button>
            </div>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  def map(assigns) do
    assigns = assign_new(assigns, :class, fn -> "" end)

    ~H"""
    <%= if @coords != %Geo.Point{} do %>
      <div class={@class}>
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
      </div>
    <% end %>
    """
  end

  def sort_link(
        %{
          current_field: current_field,
          default_order: default_order,
          sort_field: sort_field,
          sort_order: sort_order
        } = assigns
      ) do
    next = fn
      :desc -> :asc
      :asc -> :desc
    end

    assigns =
      if sort_field == current_field do
        # This field selected
        assign(assigns,
          icon_class: "w-5 h-5 text-gray-500 hover:text-gray-700",
          order: sort_order,
          next: next.(sort_order)
        )
      else
        # Another field selected
        assign(assigns,
          icon_class: "w-5 h-5 text-gray-300 hover:text-gray-700",
          order: default_order,
          next: default_order
        )
      end

    assigns =
      assign(
        assigns,
        :attrs,
        assigns_to_attributes(assigns, [
          :sort_field,
          :sort_order,
          :default_order,
          :current_field,
          :order,
          :icon_class,
          :next
        ])
      )

    ~H"""
    <button type="button" phx-value-field={@current_field} phx-value-order={@next} {@attrs}>
      <Icons.sort order={@order} class={@icon_class} />
    </button>
    """
  end

  def location(assigns) do
    ~H"""
    <div class="inline-flex flex-shrink-0 leading-normal">
      <Heroicons.Outline.location_marker
        aria_label="Location"
        class="w-4 h-4 mt-1 mr-1 text-gray-800"
      />
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
end
