defmodule BikeBrigadeWeb.ProgramLive.Show do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.Delivery
  alias BikeBrigade.Delivery.Item
  import BikeBrigadeWeb.CampaignHelpers

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page, :programs)
     |> assign(:users, [])}
  end

  @impl true
  @spec handle_params(map, any, Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    program = Delivery.get_program!(id, preload: [:lead, :items, campaigns: [:stats]])

    socket
    |> assign(:page_title, program.name)
    |> assign(:program, program)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    program = Delivery.get_program!(id, preload: [:lead, :items, campaigns: [:stats]])

    socket
    |> assign(:page_title, "Edit Program")
    |> assign(:program, program)
  end

  defp apply_action(socket, :new_campaign, %{"id" => id}) do
    program = Delivery.get_program!(id, preload: [:lead, :items, campaigns: [:stats]])
    campaign = Delivery.new_campaign(%{program_id: program.id})

    socket
    |> assign(:program, program)
    |> assign(:campaign, campaign)
  end

  defp apply_action(socket, :new_item, %{"id" => id}) do
    program = Delivery.get_program!(id, preload: [:lead, :items, campaigns: [:stats]])


    socket
    |> assign(:page_title, "New Item")
    |> assign(:program, program)
    |> assign(:item, %Item{program_id: program.id})
  end

  defp apply_action(socket, :edit_item, %{"id" => id, "item_id" => item_id}) do
    program = Delivery.get_program!(id, preload: [:lead, :items, campaigns: [:stats]])
    socket
    |> assign(:page_title, "Edit Item")
    |> assign(:program, program)
    |> assign(:item, Delivery.get_item!(item_id))
  end
end
