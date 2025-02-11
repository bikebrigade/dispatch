defmodule BikeBrigadeWeb.AnnouncementLive.Index do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.Delivery
  alias BikeBrigade.Delivery.Announcement

  alias BikeBrigadeWeb.CoreComponentsTwo, as: CC2

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :announcements, Delivery.list_announcements())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page, :announcements)
    |> assign(:page_title, "Edit Announcement")
    |> assign(:announcement, Delivery.get_announcement!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page, :announcements)
    |> assign(:page_title, "New Announcement")
    |> assign(:announcement, %Announcement{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page, :announcements)
    |> assign(:page_title, "Listing Announcements")
    |> assign(:announcement, nil)
  end

  @impl true
  def handle_info({BikeBrigadeWeb.AnnouncementLive.FormComponent, {:saved, announcement}}, socket) do
    {:noreply, stream_insert(socket, :announcements, announcement)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    announcement = Delivery.get_announcement!(id)
    {:ok, _} = Delivery.delete_announcement(announcement)

    {:noreply, stream_delete(socket, :announcements, announcement)}
  end
end
