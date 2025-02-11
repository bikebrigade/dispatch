defmodule BikeBrigadeWeb.AnnouncementLive.Show do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.Delivery

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page: :announcements)}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:announcement, Delivery.get_announcement!(id))}
  end

  defp page_title(:show), do: "Show Announcement"
  defp page_title(:edit), do: "Edit Announcement"
end
