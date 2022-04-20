defmodule BikeBrigadeWeb.OpportunityLive.Index do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.Delivery
  alias BikeBrigade.Delivery.{Opportunity}

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Delivery.subscribe()
    end

    {:ok,
     socket
     |> assign(:page, :opportunities)
     |> assign(:page_title, "Delivery Opportunities")
     |> assign(:selected, MapSet.new())
     |> assign(:sort_field, :program_name)
     |> assign(:sort_order, :asc)
     |> fetch_opportunities()}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Opportunity")
    |> assign(:opportunity, Delivery.get_opportunity(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Opportunity")
    |> assign(:opportunity, %Opportunity{})
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    opportunity = Delivery.get_opportunity(id)
    {:ok, _} = Delivery.delete_opportunity(opportunity)

    {:noreply, socket}
  end

  def handle_event("sort", %{"field" => field, "order" => order}, socket) do
    field = String.to_existing_atom(field)
    order = String.to_existing_atom(order)

    {:noreply,
     socket
     |> assign(:sort_field, field)
     |> assign(:sort_order, order)
     |> fetch_opportunities()}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "select",
        %{"_target" => ["selected", "all"], "selected" => selected_params},
        socket
      ) do
    %{opportunities: opportunities} = socket.assigns

    selected =
      case selected_params["all"] do
        "true" -> Enum.map(opportunities, & &1.id) |> MapSet.new()
        "false" -> MapSet.new()
      end

    {:noreply, assign(socket, :selected, selected)}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "select",
        %{"_target" => ["selected", id], "selected" => selected_params},
        socket
      ) do
    %{selected: selected} = socket.assigns

    selected =
      case selected_params[id] do
        "true" -> MapSet.put(selected, String.to_integer(id))
        "false" -> MapSet.delete(selected, String.to_integer(id))
      end

    {:noreply, assign(socket, :selected, selected)}
  end

  def handle_event("update-selected", %{"action" => action}, socket) do
    %{selected: selected} = socket.assigns

    update =
      case action do
        "publish" -> %{published: true}
        "unpublish" -> %{published: false}
      end

    # TODO: inefficient but we want to get broadcasts here
    for id <- selected do
      Delivery.get_opportunity(id)
      |> Delivery.update_opportunity(update)
    end

    {:noreply, assign(socket, :selected, MapSet.new([]))}
  end

  @impl Phoenix.LiveView
  def handle_info(
        {:opportunity_created, created_opportunity},
        socket
      ) do
    %{opportunities: opportunities} = socket.assigns
    created_opportunity = created_opportunity |> BikeBrigade.Repo.preload(:program)
    # TODO: this is not the most efficient, and will fail if we ever do pagination
    opportunities =
      Enum.sort_by(
        [created_opportunity | opportunities],
        &{String.downcase(&1.program.name), &1.delivery_start}
      )

    {:noreply, socket |> assign(:opportunities, opportunities)}
  end

  def handle_info(
        {:opportunity_updated, updated_opportunity},
        socket
      ) do
    %{opportunities: opportunities} = socket.assigns

    updated_opportunity = updated_opportunity |> BikeBrigade.Repo.preload(:program)

    opportunities =
      Enum.map(opportunities, fn o ->
        if o.id == updated_opportunity.id do
          updated_opportunity
        else
          o
        end
      end)

    {:noreply, socket |> assign(:opportunities, opportunities)}
  end

  def handle_info(
        {:opportunity_deleted, deleted_opportunity},
        socket
      ) do
    %{opportunities: opportunities} = socket.assigns

    opportunities = Enum.reject(opportunities, &(&1.id == deleted_opportunity.id))

    {:noreply,
     socket
     |> assign(:opportunities, opportunities)}
  end

  @doc "silently ignore new kinds of messages"
  def handle_info(_, socket), do: {:noreply, socket}

  defp fetch_opportunities(socket) do
    opportunities =
      Delivery.list_opportunities(
        sort_field: socket.assigns.sort_field,
        sort_order: socket.assigns.sort_order,
        preload: [:location, program: [:lead]]
      )

    assign(socket, :opportunities, opportunities)
  end

  defp check_mark(assigns) do
    ~H"""
    <%= if @value do %>
      <Heroicons.Outline.check_circle class="flex-shrink-0 w-6 h-6 mx-1 text-green-500 justify-self-end" />
    <% else %>
      <Heroicons.Outline.x_circle class="flex-shrink-0 w-6 h-6 mx-1 text-red-500 justify-self-end" />
    <% end %>
    """
  end

  defp program_lead_name(opportunity) do
    # TODO: move this into an opportunity context
    opportunity =
      opportunity
      |> BikeBrigade.Repo.preload(program: [:lead])

    if opportunity.program.lead do
      opportunity.program.lead.name
    else
      "Not set"
    end
  end
end
