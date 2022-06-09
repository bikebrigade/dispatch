defmodule BikeBrigadeWeb.ProgramLive.Show do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.Delivery
  alias BikeBrigade.Delivery.Campaign
  alias BikeBrigade.LocalizedDateTime
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

  def apply_action(socket, :show, %{"id" => id}) do
    program = Delivery.get_program!(id, preload: [:lead, :items, campaigns: [:stats]])

    socket
    |> assign(:page_title, program.name)
    |> assign(:program, program)
  end

  def apply_action(socket, :new_campaign, %{"id" => id}) do
    program = Delivery.get_program!(id, preload: [:lead, :items, campaigns: [:stats]])

    today = LocalizedDateTime.today()
    start_time = ~T[17:00:00]
    end_time = ~T[19:30:00]

    delivery_start = LocalizedDateTime.new!(today, start_time)
    delivery_end = LocalizedDateTime.new!(today, end_time)

    socket
    |> assign(:program, program)
    |> assign(:campaign, %Campaign{
      delivery_start: delivery_start,
      delivery_end: delivery_end,
      program_id: program.id
    })
  end
end
