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
  def handle_params(%{"id" => id}, _, socket) do
    program = Delivery.get_program!(id, preload: [:lead, :items, campaigns: [:stats]])

    {:noreply,
     socket
     |> assign(:page_title, program.name)
     |> assign(:program, program)}
  end
end
