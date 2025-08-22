defmodule BikeBrigadeWeb.BannerLive.Index do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.Notifications
  alias BikeBrigade.Notifications.Banner
  alias BikeBrigade.LocalizedDateTime

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page, :banners)
     |> assign(:page_title, "Banners")
     |> assign(:banners, list_banners())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Banner")
    |> assign(:banner, Notifications.get_banner!(id))
  end

  defp apply_action(socket, :new, _params) do
    today = LocalizedDateTime.today()
    start_time = ~T[17:00:00]
    end_time = ~T[19:30:00]

    turn_on_at = LocalizedDateTime.new!(today, start_time)
    turn_off_at = LocalizedDateTime.new!(today, end_time)

    socket
    |> assign(:page_title, "New Banner")
    |> assign(:banner, %Banner{turn_on_at: turn_on_at, turn_off_at: turn_off_at})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Banners")
    |> assign(:banner, nil)
  end

  @impl true
  def handle_info({BikeBrigadeWeb.BannerLive.FormComponent, {:saved, _banner}}, socket) do
    {:noreply, assign(socket, :banners, list_banners())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    banner = Notifications.get_banner!(id)
    {:ok, _} = Notifications.delete_banner(banner)

    {:noreply, assign(socket, :banners, list_banners())}
  end

  defp list_banners do
    Notifications.list_banners()
    |> BikeBrigade.Repo.preload(:created_by)
  end
end
