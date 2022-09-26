defmodule BikeBrigadeWeb.ProgramLive.Index do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.Delivery
  alias BikeBrigade.Delivery.{Program, Item}

  alias BikeBrigadeWeb.ProgramLive.ProgramForm

  import BikeBrigadeWeb.CampaignHelpers, only: [campaign_date: 1]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page, :programs)
     |> assign(:page_title, "Programs")
     |> assign(:programs, list_programs())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Program")
    |> assign(:program, Delivery.get_program!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Program")
    |> assign(:program, %Program{})
  end

  defp apply_action(socket, :new_item, %{"id" => id}) do
    program = Delivery.get_program!(id)

    socket
    |> assign(:page_title, "New Item")
    |> assign(:program, program)
    |> assign(:item, %Item{program_id: program.id})
  end

  defp apply_action(socket, :edit_item, %{"id" => id, "item_id" => item_id}) do
    socket
    |> assign(:page_title, "Edit Item")
    |> assign(:program, Delivery.get_program!(id))
    |> assign(:item, Delivery.get_item!(item_id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Programs")
    |> assign(:program, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    program = Delivery.get_program!(id)
    {:ok, _} = Delivery.delete_program(program)

    {:noreply, assign(socket, :programs, list_programs())}
  end

  defp list_programs do
    Delivery.list_programs(with_campaign_count: true, preload: [:lead, :latest_campaign])
  end
end
