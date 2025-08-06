defmodule BikeBrigadeWeb.BannerLive.Index do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.Messaging
  alias BikeBrigade.Messaging.Banner

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
    |> assign(:banner, Messaging.get_banner!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Banner")
    |> assign(:banner, %Banner{})
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
    banner = Messaging.get_banner!(id)
    {:ok, _} = Messaging.delete_banner(banner)

    {:noreply, assign(socket, :banners, list_banners())}
  end

  defp list_banners do
    Messaging.list_banners()
    |> BikeBrigade.Repo.preload(:created_by)
    |> Enum.sort_by(& &1.inserted_at, {:desc, DateTime})
  end
end
