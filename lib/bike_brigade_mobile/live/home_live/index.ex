defmodule BikeBrigadeMobile.HomeLive.Index do
  use BikeBrigadeWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page, "Home")
    }
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end
end
