defmodule BikeBrigadeWeb.OpportunityLive.OpportunityComponent do
  use BikeBrigadeWeb, :live_component

  alias BikeBrigade.LocalizedDateTime
  alias BikeBrigade.Delivery

  # TODO: DRY this with CampaignForm
  defmodule OpportunityForm do
    use BikeBrigade.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :program_id, :id
      field :delivery_date, :date
      field :start_time, :time
      field :end_time, :time
      field :signup_link, :string
      field :published, :boolean, default: false
    end

    def changeset(form, attrs \\ %{}) do
      form
      |> cast(attrs, [
        :program_id,
        :delivery_date,
        :start_time,
        :end_time,
        :signup_link,
        :published
      ])
      |> validate_required([
        :program_id,
        :delivery_date,
        :start_time,
        :end_time,
        :signup_link,
        :published
      ])
    end

    def from_opportunity(opportunity) do
      %__MODULE__{
        program_id: opportunity.program_id,
        delivery_date:
          opportunity.delivery_start && LocalizedDateTime.to_date(opportunity.delivery_start),
        start_time:
          opportunity.delivery_start && LocalizedDateTime.to_time!(opportunity.delivery_start),
        end_time: opportunity.delivery_end && LocalizedDateTime.to_time!(opportunity.delivery_end),
        signup_link: opportunity.signup_link,
        published: opportunity.published
      }
    end

    def to_opportunity_params(form, attrs \\ %{}) do
      case changeset(form, attrs) |> apply_action(:validate) do
        {:ok, struct} ->
          %__MODULE__{delivery_date: delivery_date, start_time: start_time, end_time: end_time} =
            struct

          params =
            struct
            |> Map.from_struct()
            |> Map.put(:delivery_start, LocalizedDateTime.new!(delivery_date, start_time))
            |> Map.put(:delivery_end, LocalizedDateTime.new!(delivery_date, end_time))

          {:ok, params}

        other ->
          other
      end
    end
  end

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, assign(socket, :editing, false)}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    socket =
      case assigns do
        %{opportunity: opportunity} ->
          opportunity_form = OpportunityForm.from_opportunity(opportunity)

          socket
          |> assign(:opportunity_form, opportunity_form)
          |> assign(:changeset, OpportunityForm.changeset(opportunity_form))

        _ ->
          socket
      end

    {:ok, socket |> assign(assigns)}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <tr id={@id}>
      <%= if @editing do %>
        <.form id={"opportunity-form-#{@id}"} let={f} for={@changeset} phx-target={@myself} phx-submit="save">
          <td class="py-4 pl-3 pr-1 text-sm leading-5 text-gray-500 border-b border-gray-200"></td>
          <td class="px-6 py-4 text-sm leading-5 text-gray-500 border-b border-gray-200">
            <div class="rounded-md shadow-sm">
              <%= select f, :program_id,  program_options(), form: f.id, phx_debounce: "blur", class: "block w-full py-2 pl-3 pr-10 mt-1 text-xs border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500" %>
            </div>
            <%= error_tag f, :program_id %>
          </td>
          <td class="px-6 py-4 text-sm leading-5 text-gray-500 border-b border-gray-200">
            <div>
              <div class="my-1 rounded-md shadow-sm" >
                <%= date_input f, :delivery_date, form: f.id, class: "block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5"  %>
              </div>
              <%= error_tag f, :delivery_date %>
            </div>
          </td>
          <td class="px-6 py-4 text-sm leading-5 text-gray-500 border-b border-gray-200">
            <div class="flex flex-col items-center space-y-1">
              <div>
                <%= label f, :start_time, class: "font-medium text-gray-700" do %>
                  Start Time
                <% end %>
                <div class="my-1 rounded-md shadow-sm" >
                  <%= time_input f, :start_time, form: f.id, placeholder: "HELLO", class: "block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5"  %>
                </div>
                <%= error_tag f, :start_time %>
              </div>
              <div>
                <%= label f, :end_time, class: "font-medium text-gray-700" do %>
                  End Time
                <% end %>
                <div class="my-1 rounded-md shadow-sm" >
                  <%= time_input f, :end_time, form: f.id, class: "block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5"  %>
                </div>
                <%= error_tag f, :end_time %>
              </div>
            </div>
          </td>
          <td class="px-6 py-4 text-sm leading-5 text-gray-500 border-b border-gray-200">
            <div class="rounded-md shadow-sm ">
              <%= textarea f, :signup_link, form: f.id, phx_debounce: "blur", rows: 1, class: "block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5" %>
            </div>
            <%= error_tag f, :signup_link %>
          </td>
          <td class="px-6 py-4 text-sm leading-5 text-gray-500 border-b border-gray-200">
            <%= if @id != :new do %>
              <a href={Routes.program_index_path(@socket, :edit, @opportunity.program)} class="link">Edit Program to change lead</a>
            <% end %>
          </td>
          <td class="px-6 py-4 text-sm leading-5 text-gray-500 border-b border-gray-200">
            <div class="rounded-md shadow-sm ">
              <%= checkbox f, :published, form: f.id, phx_debounce: "blur", rows: 1, class: "focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300 rounded" %>
            </div>
            <%= error_tag f, :published %>
          </td>
          <td class="px-6 py-4 space-x-1 space-y-1 text-right border-b border-gray-200">
            <C.button type="submit" form={f.id} size={:xsmall} color={:secondary}>Save</C.button>
            <C.button phx-click="cancel" phx-target={@myself} size={:xsmall} color={:white}>Cancel</C.button>
          </td>
        </.form>
      <% else %>
        <%# New rows have no data and are only for editing%>
        <%= if @id != :new do %>
          <td class="py-4 pl-3 pr-1 text-sm leading-5 text-gray-500 border-b border-gray-200">
            <%= checkbox :selected, "#{@opportunity.id}",
              form: "selected",
              value: @selected,
              class: "w-4 h-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500" %>
          </td>
          <td class="px-6 py-4 text-sm leading-5 text-gray-500 border-b border-gray-200">
            <%= live_redirect to: Routes.program_show_path(@socket, :show, @opportunity.program), class: "link" do %>
              <%= @opportunity.program.name %>
            <% end %>
          </td>
          <td class="px-6 py-4 text-sm leading-5 text-gray-500 border-b border-gray-200">
            <C.date date={@opportunity.delivery_start}/>
          </td>
          <td class="px-6 py-4 text-sm leading-5 text-gray-500 border-b border-gray-200">
            <%= just_time(@opportunity.delivery_start) %>-
            <%= just_time(@opportunity.delivery_end) %>
          </td>
          <td class="px-6 py-4 text-sm leading-5 text-center text-gray-500 break-all border-b border-gray-200 xl:text-left">
            <a href={@opportunity.signup_link} class="inline-block link">
              <span class="xl:hidden"><%= Heroicons.Outline.link(aria_label: "Link to signup" , class: "flex-shrink-0 w-5" ) %></span>
              <span class="hidden text-xs xl:inline"><%= @opportunity.signup_link %></span>
            </a>
          </td>
          <td class="px-6 py-4 text-sm leading-5 text-gray-500 break-all border-b border-gray-200 whitespace-nowrap">
            <%= program_lead_name(@opportunity) %>
          </td>
          <td class="px-6 py-4 text-sm leading-5 text-gray-500 border-b border-gray-200">
            <.check_mark value={@opportunity.published} />
          </td>
          <td class="px-6 py-4 space-x-1 space-y-1 text-right border-b border-gray-200">
            <C.button phx-click="edit" phx-target={@myself} size={:xsmall} color={:white}>Edit</C.button>
            <C.button phx-click="delete" data-confirm="Are you dure?" phx-target={@myself} size={:xsmall} color={:lightred}>Delete</C.button>
          </td>
        <% end %>
      <% end %>
    </tr>
    """
  end

  def handle_event("edit", _, socket) do
    {:noreply,
     socket
     |> assign(:editing, true)}
  end

  def handle_event("cancel", _, socket) do
    {:noreply,
     socket
     |> assign(:editing, false)}
  end

  def handle_event("delete", _, socket) do
    %{opportunity: opportunity} = socket.assigns
    {:ok, _} = Delivery.delete_opportunity(opportunity)
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", %{"opportunity_form" => opportunity_form_params}, socket) do
    %{opportunity: opportunity, opportunity_form: opportunity_form} = socket.assigns

    changeset = OpportunityForm.changeset(opportunity_form, opportunity_form_params)

    with {:ok, _} <- Ecto.Changeset.apply_action(changeset, :validate),
         {:ok, params} <-
           OpportunityForm.to_opportunity_params(opportunity_form, opportunity_form_params),
         {:ok, _opportunity} <- Delivery.create_or_update_opportunity(opportunity, params) do
      {:noreply,
       socket
       |> assign(:editing, false)}
    else
      {:error, _changeset} ->
        {:noreply, assign(socket, :changeset, changeset |> Map.put(:action, :insert))}
    end
  end

  defp just_time(datetime) do
    LocalizedDateTime.localize(datetime)
    |> Calendar.strftime("%-I:%M%p")
  end

  defp check_mark(assigns) do
    ~H"""
    <%= if @value do %>
      <%= Heroicons.Outline.check_circle(class: "flex-shrink-0 w-6 h-6 mx-1 text-green-500 justify-self-end") %>
    <% else %>
      <%= Heroicons.Outline.x_circle(class: "flex-shrink-0 w-6 h-6 mx-1 text-red-500 justify-self-end") %>
    <% end %>
    """
  end

  # TODO: DRY this
  defp program_options do
    programs =
      for p <- Delivery.list_programs() do
        {p.name, p.id}
      end

    [{"", nil} | programs]
  end

  defp program_lead_name(opportunity) do
    # TODO: move this into an opportunity context
    opportunity = opportunity
    |> BikeBrigade.Repo.preload(program: [:lead])

    if opportunity.program.lead do
      opportunity.program.lead.name
    else
      "Not set"
    end
  end
end
