defmodule BikeBrigadeWeb.CoreComponents do
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  alias BikeBrigade.Riders.Rider
  alias BikeBrigade.LocalizedDateTime
  alias BikeBrigadeWeb.Components.{Icons, RiderSelectionComponent}

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
  slot :inner_block, required: true

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
      <Icons.circle :if={@date == @today} class="w-2 h-2 ml-1 text-indigo-400" />
      <span :if={@date.year != @today.year} class="ml-1 text-sm font-semibold">
        <%= Calendar.strftime(@date, "%y") %>
      </span>
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
  Renders a header with title.
  """
  attr :class, :string, default: nil
  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "sm:flex sm:items-center", @class]}>
      <div class="sm:flex-auto">
        <h1 class="text-xl font-semibold text-gray-900">
          <%= render_slot(@inner_block) %>
        </h1>
        <p :if={@subtitle != []} class="mt-2 text-sm text-gray-700">
          <%= render_slot(@subtitle) %>
        </p>
      </div>
      <div class="mt-4 sm:mt-0 sm:ml-16 sm:flex-none"><%= render_slot(@actions) %></div>
    </header>
    """
  end

  @doc """
  Renders an input with label and error messages.
  A `%Phoenix.HTML.Form{}` and field name may be passed to the input
  to build input names and error messages, or all the attributes and
  errors may be passed explicitly.
  ## Examples
      <.input field={{f, :email}} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any
  attr :name, :any
  attr :label, :string, default: nil
  attr :help_text, :string, default: nil

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select tel text time url week)

  attr :value, :any
  attr :field, :any, doc: "a %Phoenix.HTML.Form{}/field name tuple, for example: {f, :email}"
  attr :errors, :list
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :rest, :global, include: ~w(autocomplete checked disabled form max maxlength min minlength
                                   multiple pattern placeholder readonly required size step)
  slot :inner_block

  def input(%{field: {f, field}} = assigns) do
    assigns
    |> assign(field: nil)
    |> assign_new(:name, fn ->
      name = Phoenix.HTML.Form.input_name(f, field)
      if assigns.multiple, do: name <> "[]", else: name
    end)
    |> assign_new(:id, fn -> Phoenix.HTML.Form.input_id(f, field) end)
    |> assign_new(:value, fn -> Phoenix.HTML.Form.input_value(f, field) end)
    |> assign_new(:errors, fn -> translate_errors(f.errors || [], field) end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns = assign_new(assigns, :checked, fn -> input_equals?(assigns.value, "true") end)

    ~H"""
    <div phx-feedback-for={@name} class="relative flex items-start">
      <div class="flex items-center h-5">
        <input type="hidden" name={@name} value="false" />
        <input
          type="checkbox"
          id={@id || @name}
          name={@name}
          value="true"
          checked={@checked}
          class="w-4 h-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500"
          {@rest}
        />
      </div>
      <div class="ml-3 text-sm">
        <.label for={@id}><%= @label %></.label>
        <p if={@help_text} id="comments-description" class="text-gray-500">
          <%= @help_text %>
        </p>
      </div>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <select
        id={@id}
        name={@name}
        class="block w-full px-3 py-2 mt-1 bg-white border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-zinc-500 focus:border-zinc-500 sm:text-sm"
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt}><%= @prompt %></option>
        <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
      </select>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <textarea
        id={@id || @name}
        name={@name}
        class={[
          input_border(@errors),
          "mt-1 block min-h-[6rem] w-full rounded-md border-gray-300 shadow-sm py-[calc(theme(spacing.2)-1px)] px-[calc(theme(spacing.3)-1px)]]",
          "text-gray-900 focus:outline-none sm:text-sm sm:leading-6",
          "phx-no-feedback:border-gray-300 phx-no-feedback:focus:border-indigo-500 phx-no-feedback:focus:ring-indigo-500",
          "disabled:bg-slate-50 disabled:text-slate-500 disabled:border-slate-200 disabled:shadow-none"
        ]}
        {@rest}
      ><%= @value %></textarea>
      <p :if={@help_text} class="mt-2 text-sm text-gray-500">
        <%= @help_text %>
      </p>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <input
        type={@type}
        name={@name}
        id={@id || @name}
        value={@value}
        class={[
          input_border(@errors),
          "mt-1 block w-full rounded-md border-gray-300 shadow-sm py-[calc(theme(spacing.2)-1px)] px-[calc(theme(spacing.3)-1px)]",
          "text-gray-900 focus:outline-none sm:text-sm sm:leading-6",
          "phx-no-feedback:border-gray-300 phx-no-feedback:focus:border-indigo-500 phx-no-feedback:focus:ring-indigo-500",
          "disabled:bg-slate-50 disabled:text-slate-500 disabled:border-slate-200 disabled:shadow-none"
        ]}
        {@rest}
      />
      <p :if={@help_text} class="mt-2 text-sm text-gray-500">
        <%= @help_text %>
      </p>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  attr :id, :any
  attr :name, :any
  attr :field, :any, doc: "a %Phoenix.HTML.Form{}/field name tuple, for example: {f, :email}"
  attr :selected_rider, Rider, default: nil
  attr :label, :string, default: nil
  attr :help_text, :string, default: nil
  attr :rest, :global, include: ~w(multi)

  def rider_select(%{field: {f, field}} = assigns) do
    assigns =
      assigns
      |> assign_new(:name, fn -> Phoenix.HTML.Form.input_name(f, field) end)
      |> assign_new(:id, fn -> Phoenix.HTML.Form.input_id(f, field) end)

    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>

      <.live_component
        module={RiderSelectionComponent}
        id={@id}
        input_name={@name}
        selected_rider={@selected_rider}
        {@rest}
      />
      <p :if={@help_text} class="mt-2 text-sm text-gray-500">
        <%= @help_text %>
      </p>
    </div>
    """
  end

  defp input_border([] = _errors),
    do: "border-gray-300 focus:border-indigo-500 focus:ring-indigo-500"

  defp input_border([_ | _] = _errors),
    do: "border-red-300 focus:border-red-500 focus:ring-red-500"

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-sm font-medium text-gray-700">
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="flex gap-3 mt-3 text-sm leading-6 phx-no-feedback:hidden text-rose-600">
      <Heroicons.exclamation_circle mini class="mt-0.5 h-5 w-5 flex-none fill-rose-500" />
      <%= render_slot(@inner_block) %>
    </p>
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
        <div :if={@location.unit} class="text-sm">
          <span class="font-bold">Unit:</span> <%= @location.unit %>
        </div>
        <div :if={@location.buzzer} class="text-sm">
          <span class="font-bold">Buzz:</span> <%= @location.buzzer %>
        </div>
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
  Renders a modal.
  ## Examples
      <.modal id="confirm-modal">
        Are you sure?
        <:confirm>OK</:confirm>
        <:cancel>Cancel</:cancel>
      </.modal>
  JS commands may be passed to the `:on_cancel` and `on_confirm` attributes
  for the caller to react to each button press, for example:
      <.modal id="confirm" on_confirm={JS.push("delete")} on_cancel={JS.navigate(~p"/posts")}>
        Are you sure you?
        <:confirm>OK</:confirm>
        <:cancel>Cancel</:cancel>
      </.modal>
  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  attr :on_confirm, JS, default: %JS{}

  slot :inner_block, required: true
  slot :title
  slot :subtitle
  slot :confirm
  slot :cancel

  def modal(assigns) do
    ~H"""
    <div id={@id} phx-mounted={@show && show_modal(@id)} class="relative z-50 hidden">
      <div id={"#{@id}-bg"} class="fixed inset-0 transition-opacity bg-zinc-50/90" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex items-center justify-center min-h-full">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-mounted={@show && show_modal(@id)}
              phx-window-keydown={hide_modal(@on_cancel, @id)}
              phx-key="escape"
              phx-click-away={hide_modal(@on_cancel, @id)}
              class="relative hidden transition bg-white shadow-lg rounded-2xl p-14 shadow-zinc-700/10 ring-1 ring-zinc-700/10"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={hide_modal(@on_cancel, @id)}
                  type="button"
                  class="flex-none p-3 -m-3 opacity-20 hover:opacity-40"
                  aria-label="Close"
                >
                  <Heroicons.x_mark solid class="w-5 h-5 stroke-current" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                <header :if={@title != []}>
                  <h1 id={"#{@id}-title"} class="text-lg font-semibold leading-8 text-zinc-800">
                    <%= render_slot(@title) %>
                  </h1>
                  <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-zinc-600">
                    <%= render_slot(@subtitle) %>
                  </p>
                </header>
                <%= render_slot(@inner_block) %>
                <div :if={@confirm != [] or @cancel != []} class="flex items-center gap-5 mb-4 ml-6">
                  <.button
                    :for={confirm <- @confirm}
                    id={"#{@id}-confirm"}
                    phx-click={@on_confirm}
                    phx-disable-with
                    class="px-3 py-2"
                  >
                    <%= render_slot(confirm) %>
                  </.button>
                  <.link
                    :for={cancel <- @cancel}
                    phx-click={hide_modal(@on_cancel, @id)}
                    class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
                  >
                    <%= render_slot(cancel) %>
                  </.link>
                </div>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a simple form.
  ## Examples
      <.simple_form :let={f} for={:user} phx-change="validate" phx-submit="save">
        <.input field={{f, :email}} label="Email"/>
        <.input field={{f, :username}} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, default: nil, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="mt-4 space-y-4 bg-white">
        <%= render_slot(@inner_block, f) %>
        <div :for={action <- @actions} class="flex items-center justify-end gap-6 mt-2">
          <%= render_slot(action, f) %>
        </div>
      </div>
    </.form>
    """
  end

  @doc """
    Renders a slideover.
  """

  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :wide, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  attr :on_confirm, JS, default: %JS{}

  slot :inner_block, required: true
  slot :title
  slot :subtitle

  slot :confirm do
    attr :form, :string
  end

  slot :cancel

  def slideover(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_slideover(@id)}
      class="relative z-10 hidden"
      aria-labelledby={"#{@id}-title"}
      role="dialog"
      aria-modal="true"
    >
      <!-- Background backdrop, show/hide based on slide-over state. -->
      <div id={"#{@id}-bg"} class="fixed inset-0"></div>

      <div class="fixed inset-0 overflow-hidden">
        <div class="absolute inset-0 overflow-hidden">
          <div class="fixed inset-y-0 right-0 flex max-w-full pl-10 pointer-events-none sm:pl-16">
            <!--
              Slide-over panel, show/hide based on slide-over state.

              Entering: "transform transition ease-in-out duration-500 sm:duration-700"
                From: "translate-x-full"
                To: "translate-x-0"
              Leaving: "transform transition ease-in-out duration-500 sm:duration-700"
                From: "translate-x-0"
                To: "translate-x-full"
            -->
            <div class={[
              "w-screen pointer-events-auto",
              if(@wide, do: "max-w-4xl", else: "max-w-2xl")
            ]}>
              <.focus_wrap
                id={"#{@id}-container"}
                phx-mounted={@show && show_slideover(@id)}
                phx-window-keydown={hide_slideover(@on_cancel, @id)}
                phx-key="escape"
                phx-click-away={hide_slideover(@on_cancel, @id)}
                class="flex flex-col h-full overflow-y-scroll bg-white shadow-xl"
              >
                <div class="flex-1">
                  <!-- Header -->
                  <div class="px-4 py-6 bg-gray-50 sm:px-6">
                    <div class="flex items-start justify-between space-x-3">
                      <header :if={@title != []} class="space-y-1">
                        <h1 class="text-lg font-medium text-gray-900" id={"#{@id}-title"}>
                          <%= render_slot(@title) %>
                        </h1>
                        <p :if={@subtitle != []} class="text-sm text-gray-500">
                          <%= render_slot(@subtitle) %>
                        </p>
                      </header>
                      <div class="flex items-center h-7">
                        <button
                          phx-click={hide_slideover(@on_cancel, @id)}
                          type="button"
                          class="text-gray-400 hover:text-gray-500"
                        >
                          <span class="sr-only">Close panel</span>
                          <!-- Heroicon name: outline/x-mark -->
                          <Heroicons.x_mark mini class="w-6 h-6" />
                        </button>
                      </div>
                    </div>
                  </div>
                  <div class="p-4 sm:p-6">
                    <%= render_slot(@inner_block) %>
                  </div>
                </div>
                <!-- Action buttons -->
                <div
                  :if={@confirm != [] or @cancel != []}
                  class="flex-shrink-0 px-4 py-5 border-t border-gray-200 sm:px-6"
                >
                  <div class="flex justify-end space-x-3">
                    <.button
                      :for={cancel <- @cancel}
                      phx-click={hide_slideover(@on_cancel, @id)}
                      color={:white}
                    >
                      <%= render_slot(cancel) %>
                    </.button>
                    <.button
                      :for={confirm <- @confirm}
                      id={"#{@id}-confirm"}
                      {Map.take(confirm, [:form, :type, :"phx-disable-with"])}
                    >
                      <%= render_slot(confirm) %>
                    </.button>
                  </div>
                </div>
              </.focus_wrap>
            </div>
          </div>
        </div>
      </div>
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

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true

  attr :checkboxes, :string, default: nil
  attr :checkbox_checked?, :any
  attr :checkbox_phx_change, JS, default: %JS{}

  slot :col, required: true do
    attr :show_at, :atom, values: [:small, :medium, :large]
    attr :unstack_at, :atom, values: [:small, :medium, :large]
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    ~H"""
    <div id={@id} class="flex flex-col mt-8">
      <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
        <div class="inline-block min-w-full py-2 align-middle md:px-6 lg:px-8">
          <div class="relative overflow-hidden shadow ring-1 ring-black ring-opacity-5 md:rounded-lg">
            <form :if={@checkboxes} id={"#{@id}-form"} phx-change={@checkbox_phx_change}></form>
            <div class="absolute top-0 flex items-center hidden h-12 space-x-3 left-12 bg-gray-50 sm:left-16">
              <button
                type="button"
                class="inline-flex items-center rounded border border-gray-300 bg-white px-2.5 py-1.5 text-xs font-medium text-gray-700 shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-30"
              >
                Bulk edit
              </button>
              <button
                type="button"
                class="inline-flex items-center rounded border border-gray-300 bg-white px-2.5 py-1.5 text-xs font-medium text-gray-700 shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-30"
              >
                Delete all
              </button>
            </div>
            <table class="min-w-full divide-y divide-gray-300">
              <thead class="bg-gray-50">
                <tr>
                  <th :if={@checkboxes} scope="col" class="relative w-12 px-6 sm:w-16 sm:px-8">
                    <input
                      type="checkbox"
                      form={"#{@id}-form"}
                      class="absolute w-4 h-4 -mt-2 text-indigo-600 border-gray-300 rounded left-4 top-1/2 focus:ring-indigo-500 sm:left-6"
                    />
                  </th>
                  <th
                    :for={{col, i} <- Enum.with_index(@col)}
                    scope="col"
                    class={[
                      "py-3.5 text-left text-sm font-semibold text-gray-900",
                      if(i == 0, do: "pl-4 pr-3 sm:pl-6", else: "px-3"),
                      if(col[:show_at], do: "hidden " <> display_at_size(col[:show_at], "table-cell")),
                      if(col[:unstack_at],
                        do: "hidden " <> display_at_size(col[:unstack_at], "table-cell")
                      )
                    ]}
                  >
                    <%= col[:label] %>
                  </th>
                  <th :if={@action != []} scope="col" class="relative py-3.5 pl-3 pr-4 sm:pr-6">
                    <span class="sr-only">Actions</span>
                  </th>
                </tr>
              </thead>
              <tbody class="bg-white divide-y divide-gray-200">
                <tr
                  :for={row <- @rows}
                  id={"#{@id}-#{Phoenix.Param.to_param(row)}"}
                  class={if @checkboxes && @checkbox_checked?.(row), do: "bg-gray-50"}
                >
                  <td :if={@checkboxes} class="relative w-12 px-6 sm:w-16 sm:px-8">
                    <div
                      :if={@checkbox_checked?.(row)}
                      class="absolute inset-y-0 left-0 w-0.5 bg-indigo-600"
                    />
                    <input
                      type="hidden"
                      name={Phoenix.HTML.Form.input_name(@checkboxes, Phoenix.Param.to_param(row))}
                      value="false"
                      form={"#{@id}-form"}
                    />
                    <input
                      type="checkbox"
                      id={Phoenix.HTML.Form.input_id(@checkboxes, Phoenix.Param.to_param(row))}
                      name={Phoenix.HTML.Form.input_name(@checkboxes, Phoenix.Param.to_param(row))}
                      value="true"
                      checked={@checkbox_checked?.(row)}
                      form={"#{@id}-form"}
                      class="absolute w-4 h-4 -mt-2 text-indigo-600 border-gray-300 rounded left-4 top-1/2 focus:ring-indigo-500 sm:left-6"
                    />
                  </td>
                  <td
                    :for={{col, i} <- Enum.with_index(@col)}
                    class={[
                      "py-4 text-sm text-gray-500 whitespace-nowrap",
                      if(i == 0, do: "pl-4 pr-3 sm:pl-6 font-medium", else: "px-3"),
                      if(col[:show_at], do: "hidden " <> display_at_size(col[:show_at], "table-cell")),
                      if(col[:unstack_at],
                        do: "hidden " <> display_at_size(col[:unstack_at], "table-cell")
                      )
                    ]}
                  >
                    <%= render_slot(col, row) %>
                    <dl :if={i == 0} class="">
                      <div
                        :for={col <- Enum.drop(@col, 1)}
                        :if={col[:unstack_at]}
                        class={display_at_size(col[:unstack_at], "hidden")}
                      >
                        <dt class="sr-only">
                          <%= col[:label] %>
                        </dt>
                        <dd class="mt-1 text-gray-700 truncate"><%= render_slot(col, row) %></dd>
                      </div>
                    </dl>
                  </td>

                  <td
                    :if={@action != []}
                    class="relative py-4 pl-3 pr-4 space-x-2 text-sm font-medium text-right whitespace-nowrap sm:pr-6"
                  >
                    <span :for={action <- @action}>
                      <%= render_slot(action, row) %>
                    </span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp display_at_size(size, display_class) do
    case size do
      :small -> "sm:#{display_class}"
      :medium -> "md:#{display_class}"
      :large -> "lg:#{display_class}"
      nil -> ""
    end
  end

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
      <leaflet-map
        :if={@coords != %Geo.Point{}}
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
      <div :if={@coords == %Geo.Point{}} class="p-2">Location Unknown</div>
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

  def show_slideover(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(to: "##{id}-bg")
    |> JS.show(
      to: "##{id}-container",
      time: 500,
      transition: {
        "transform transition ease-in-out duration-500",
        "translate-x-full",
        "translate-x-0"
      }
    )
    |> JS.focus_first(to: "##{id}-container")
  end

  def hide_slideover(js \\ %JS{}, id) do
    js
    |> JS.hide(to: "##{id}-bg")
    |> JS.hide(
      to: "##{id}-container",
      time: 500,
      transition:
        {"transform transition ease-in-out duration-500", "translate-x-0", "translate-x-full"}
    )
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.pop_focus()
  end

  @doc """
  Translates an error message.
  """
  def translate_error({msg, opts}) do
    # Because the error messages we show in our forms and APIs
    # are defined inside Ecto, we need to translate them dynamically.
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", fn _ -> to_string(value) end)
    end)
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  defp input_equals?(val1, val2) do
    Phoenix.HTML.html_escape(val1) == Phoenix.HTML.html_escape(val2)
  end
end
