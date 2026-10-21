defmodule BikeBrigadeWeb.Dev.ComponentGalleryLive do
  @moduledoc """
  Dev-only page (/dev/components) rendering every core component in each of its
  states, so UI changes can be checked in the browser in one place.
  """
  use BikeBrigadeWeb, :live_view

  defmodule Row do
    @moduledoc false
    @derive {Phoenix.Param, key: :id}
    defstruct [:id, :name, :role, :email]
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page, :dev_components)
     |> assign(:page_title, "Component gallery")
     |> assign(:rows, rows())
     |> assign(:selected, MapSet.new([2]))
     |> assign(:sort_field, :name)
     |> assign(:sort_order, :asc)
     |> assign(:toggle_on, true)
     |> assign(:filter, "all")
     |> assign(:form, blank_form())
     |> assign(:error_form, error_form())}
  end

  @impl true
  def handle_event("flash", %{"kind" => kind}, socket) do
    kind = String.to_existing_atom(kind)
    {:noreply, put_flash(socket, kind, "This is a #{kind} flash message.")}
  end

  def handle_event("toggle", _params, socket) do
    {:noreply, update(socket, :toggle_on, &(!&1))}
  end

  def handle_event("filter", %{"filter" => value}, socket) do
    {:noreply, assign(socket, :filter, value)}
  end

  def handle_event("sort", %{"field" => field, "order" => order}, socket) do
    {:noreply,
     assign(socket,
       sort_field: String.to_existing_atom(field),
       sort_order: String.to_existing_atom(order)
     )}
  end

  def handle_event("select", %{"rows" => rows}, socket) do
    selected =
      for {id, "true"} <- rows, id != "all", into: MapSet.new(), do: String.to_integer(id)

    {:noreply, assign(socket, :selected, selected)}
  end

  def handle_event(_event, _params, socket), do: {:noreply, socket}

  defp rows do
    [
      %Row{id: 1, name: "Lindsay Walton", role: "Dispatcher", email: "lindsay@example.com"},
      %Row{id: 2, name: "Courtney Henry", role: "Rider", email: "courtney@example.com"},
      %Row{id: 3, name: "Tom Cook", role: "Rider", email: "tom@example.com"}
    ]
  end

  defp blank_form do
    to_form(
      %{
        "name" => "Ada Lovelace",
        "notes" => "",
        "role" => "dispatcher",
        "capacity" => "medium",
        "active" => "true",
        "start_date" => "2026-10-21",
        "start_time" => "12:00"
      },
      as: :demo
    )
  end

  defp error_form do
    to_form(%{"email" => "not-an-email", "notes" => "", "role" => ""},
      as: :demo_errors,
      errors: [
        email: {"is not a valid email", []},
        notes: {"can't be blank", []},
        role: {"can't be blank", []}
      ]
    )
  end

  attr :title, :string, required: true
  slot :inner_block, required: true

  defp section(assigns) do
    ~H"""
    <section class="py-6 border-b border-base-300">
      <h2 class="mb-4 text-sm font-semibold tracking-wide uppercase text-base-content/60">
        {@title}
      </h2>
      {render_slot(@inner_block)}
    </section>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="px-4 pb-24 sm:px-6 lg:px-8">
      <.header>
        Component gallery
        <:subtitle>Every core component in each of its states. Dev only.</:subtitle>
      </.header>

      <.section title="Buttons: colors">
        <div class="flex flex-wrap items-center gap-2">
          <.button
            :for={color <- ~w(primary secondary white green red lightred clear black disabled)a}
            color={color}
            type="button"
          >
            {color}
          </.button>
          <.button type="button" disabled>disabled attr</.button>
          <.button navigate={~p"/dev/components"}>as link</.button>
        </div>
      </.section>

      <.section title="Buttons: sizes and rounding">
        <div class="flex flex-wrap items-center gap-2">
          <.button
            :for={size <- ~w(xxsmall xsmall small medium large xlarge)a}
            size={size}
            type="button"
          >
            {size}
          </.button>
        </div>
        <div class="flex flex-wrap items-center gap-2 mt-3">
          <.button
            :for={rounded <- ~w(none small normal medium full)a}
            rounded={rounded}
            type="button"
          >
            rounded {rounded}
          </.button>
        </div>
      </.section>

      <.section title="Buttons: a row that wraps (resize to check alignment)">
        <div class="max-w-xs">
          <div class="shrink-0 space-y-1 md:space-y-0 md:space-x-2 md:flex">
            <.button size={:xsmall} color={:white} navigate={~p"/dev/components"}>Edit</.button>
            <.button size={:xsmall} color={:white} navigate={~p"/dev/components"}>
              Duplicate
            </.button>
            <.button size={:xsmall} color={:lightred} navigate={~p"/dev/components"}>
              Delete
            </.button>
          </div>
        </div>
      </.section>

      <.section title="Form inputs">
        <.simple_form for={@form} phx-change="noop" phx-submit="noop">
          <div class="grid max-w-3xl grid-cols-1 gap-4 sm:grid-cols-2">
            <.input field={@form[:name]} label="Text" help_text="Help text under the input" />
            <.input field={@form[:start_date]} type="date" label="Date" />
            <.input field={@form[:start_time]} type="time" label="Time" />
            <.input
              field={@form[:capacity]}
              type="select"
              label="Select"
              options={[Small: "small", Medium: "medium", Large: "large"]}
            />
            <.input field={@form[:notes]} type="textarea" label="Textarea" placeholder="Placeholder" />
            <.input
              id="demo_disabled"
              errors={[]}
              name="disabled"
              value="Can't touch this"
              label="Disabled"
              disabled
            />
            <.input
              field={@form[:active]}
              type="checkbox"
              label="Checkbox"
              help_text="Checkbox help text"
            />
            <.radio_group field={@form[:role]} label="Radio group">
              <:radio value="dispatcher" label="Dispatcher" />
              <:radio value="rider" label="Rider" />
            </.radio_group>
          </div>
          <:actions>
            <.button type="button" color={:white}>Cancel</.button>
            <.button type="submit">Save</.button>
          </:actions>
        </.simple_form>
      </.section>

      <.section title="Form inputs with errors">
        <.simple_form for={@error_form} phx-change="noop" phx-submit="noop">
          <div class="grid max-w-3xl grid-cols-1 gap-4 sm:grid-cols-2">
            <.input field={@error_form[:email]} type="email" label="Email" />
            <.input
              field={@error_form[:role]}
              type="select"
              label="Role"
              prompt="Choose a role"
              options={[Dispatcher: "dispatcher", Rider: "rider"]}
            />
            <.input field={@error_form[:notes]} type="textarea" label="Notes" />
          </div>
        </.simple_form>
      </.section>

      <.section title="Toggle, filter buttons, date, tooltip">
        <div class="flex flex-wrap items-center gap-6">
          <.toggle enabled={@toggle_on} label="Toggle" phx-click="toggle" />
          <div class="flex gap-2">
            <.filter_button
              :for={value <- ~w(all available assigned)}
              selected={@filter == value}
              phx-click="filter"
              phx-value-filter={value}
            >
              {value}
            </.filter_button>
          </div>
          <.date date={~D[2026-10-21]} />
          <.date date={~D[2025-03-14]} navigate={~p"/dev/components"} />
          <.with_tooltip>
            <span class="text-sm underline decoration-dotted">Hover for tooltip</span>
            <:tooltip>Tooltip text</:tooltip>
          </.with_tooltip>
        </div>
      </.section>

      <.section title="Header">
        <.header>
          Page title
          <:subtitle>A subtitle explaining the page.</:subtitle>
          <:actions>
            <.button type="button">Primary action</.button>
          </:actions>
        </.header>
        <.header small class="mt-6">Small header</.header>
      </.section>

      <.section title="Table: checkboxes, sorting, actions, stacked columns">
        <form id="gallery-rows" phx-change="select"></form>
        <.table
          id="gallery-table"
          rows={@rows}
          checkboxes="gallery-rows"
          checkboxes_selected={@selected}
          sort_click={JS.push("sort")}
          sort_field={@sort_field}
          sort_order={@sort_order}
        >
          <:bulk_action>
            <.button size={:xsmall} color={:white} type="button">Bulk action</.button>
          </:bulk_action>
          <:col :let={row} label="Name" sortable_field={:name} default_order={:asc}>
            {row.name}
          </:col>
          <:col :let={row} label="Role" unstack_at={:small}>{row.role}</:col>
          <:col :let={row} label="Email" show_at={:large}>{row.email}</:col>
          <:action :let={_row}>
            <.link navigate={~p"/dev/components"} class="link">Edit</.link>
          </:action>
        </.table>
      </.section>

      <.section title="Flash, modal, slide-over">
        <div class="flex flex-wrap gap-2">
          <.button
            :for={kind <- ~w(info warn error)}
            type="button"
            color={:white}
            phx-click="flash"
            phx-value-kind={kind}
          >
            Flash {kind}
          </.button>
          <.button type="button" phx-click={show_modal("gallery-modal")}>Open modal</.button>
          <.button type="button" phx-click={show_slideover("gallery-slideover")}>
            Open slide-over
          </.button>
        </div>

        <.modal id="gallery-modal">
          <:title>Modal title</:title>
          <:subtitle>Modal subtitle</:subtitle>
          <p class="py-4 text-sm">Modal body text.</p>
          <:confirm>Confirm</:confirm>
          <:cancel>Cancel</:cancel>
        </.modal>

        <.slideover id="gallery-slideover">
          <:title>Slide-over title</:title>
          <:subtitle>Slide-over subtitle</:subtitle>
          <.simple_form for={@form} phx-change="noop">
            <.input field={@form[:name]} label="Name" />
            <.input field={@form[:notes]} type="textarea" label="Notes" />
          </.simple_form>
          <:cancel>Cancel</:cancel>
          <:confirm type="button">Save</:confirm>
        </.slideover>
      </.section>
    </div>
    """
  end
end
