defmodule BikeBrigadeWeb.OpportunityLive.Index do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.Delivery
  alias BikeBrigade.Delivery.{Opportunity}

  alias BikeBrigadeWeb.OpportunityLive.OpportunityComponent

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Delivery.subscribe()
    end

    {:ok,
     socket
     |> assign(:page, :opportunities)
     |> assign(:page_title, "Delivery Opportunities")
     |> assign(:opportunities, list_opportunities())
     |> assign(:selected, MapSet.new())}
  end

  @impl true
  def handle_event("new", _, socket) do
    send_update(OpportunityComponent,
      id: :new,
      editing: true
    )

    {:noreply, socket}
  end

  @impl true
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

  @impl true
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
      Delivery.get_opportunity!(id)
      |> Delivery.update_opportunity(update)
    end

    {:noreply, assign(socket, :selected, MapSet.new([]))}
  end

  @impl true
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

  @impl true
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

  @impl true
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

  defp list_opportunities(order_by \\ :program_name) do
    Delivery.list_opportunities(order_by: order_by, preload: [program: [:lead]])
  end
end
