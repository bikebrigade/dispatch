defmodule BikeBrigadeWeb.ProgramLive.Show do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.Delivery
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

  def apply_action(socket, :new_campaign, %{"id" => id}) do
    program = Delivery.get_program!(id, preload: [:lead, :items, campaigns: [:stats]])
    campaign = Delivery.new_campaign(%{program_id: program.id})

    socket
    |> assign(:program, program)
    |> assign(:campaign, campaign)
  end

  def apply_action(socket, _other_action, %{"id" => id}) do
    program = Delivery.get_program!(id, preload: [:lead, :items, campaigns: [:stats]])

    socket
    |> assign(:page_title, program.name)
    |> assign(:program, program)
  end
end
