defmodule BikeBrigadeWeb.RiderLive.Show do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.Riders

  @impl true
  def mount(_params, session, socket) do
    {:ok,
     socket
     |> assign(:page, :riders)}
  end

  def handle_params(%{"id" => id} = params, _url, socket) do
    rider = Riders.get_rider!(id)

    # Loading in some dummy data to reference in the template
    stats = %{deliveries: 124, campaigns: 78, distance: 240.3}

    # I don't have a good datastructure for campaign history and the schedule so lets keep those just html for now

    {:noreply,
     socket
     |> assign(:rider, rider)
     |> assign(:stats, stats)}
  end
end
