defmodule BikeBrigadeWeb.BannerLive.Index do
  use BikeBrigadeWeb, :live_view

  import BikeBrigadeWeb.BannerComponents

  alias BikeBrigade.Notifications
  alias BikeBrigade.Notifications.Banner
  alias BikeBrigade.LocalizedDateTime

  @tabs [:current, :expired]
  @sort_fields [:message, :turn_on_at, :turn_off_at]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page, :banners)
     |> assign(:page_title, "Banners")
     |> assign(:tab, :current)
     |> assign(:sort_field, :turn_on_at)
     |> assign(:sort_order, default_sort_order(:current))
     |> fetch_banners()}
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
    {:noreply, fetch_banners(socket)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    banner = Notifications.get_banner!(id)
    {:ok, _} = Notifications.delete_banner(banner)

    {:noreply, fetch_banners(socket)}
  end

  def handle_event("select-tab", %{"tab" => tab}, socket) do
    tab = parse_param(tab, @tabs, :current)

    {:noreply,
     socket
     |> assign(:tab, tab)
     |> assign(:sort_field, :turn_on_at)
     |> assign(:sort_order, default_sort_order(tab))
     |> sort_banners()}
  end

  def handle_event("sort", %{"field" => field, "order" => order}, socket) do
    {:noreply,
     socket
     |> assign(:sort_field, parse_param(field, @sort_fields, :turn_on_at))
     |> assign(:sort_order, parse_param(order, [:asc, :desc], :asc))
     |> sort_banners()}
  end

  # Current banners read best soonest-first; expired ones most-recent-first.
  defp default_sort_order(:current), do: :asc
  defp default_sort_order(:expired), do: :desc

  defp parse_param(value, allowed, default) do
    Enum.find(allowed, default, &(Atom.to_string(&1) == value))
  end

  defp fetch_banners(socket) do
    now = DateTime.utc_now()

    {expired, current} =
      Notifications.list_banners()
      |> BikeBrigade.Repo.preload(:created_by)
      |> Enum.split_with(&(DateTime.compare(&1.turn_off_at, now) == :lt))

    socket
    |> assign(:all_banners, %{current: current, expired: expired})
    |> sort_banners()
  end

  defp sort_banners(socket) do
    %{all_banners: all_banners, tab: tab, sort_field: field, sort_order: order} =
      socket.assigns

    assign(socket, :banners, sort(all_banners[tab], field, order))
  end

  defp sort(banners, :message, order),
    do: Enum.sort_by(banners, &String.downcase(&1.message), order)

  defp sort(banners, field, order),
    do: Enum.sort_by(banners, &Map.fetch!(&1, field), {order, DateTime})
end
