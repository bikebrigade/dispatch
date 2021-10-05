defmodule BikeBrigadeWeb.RiderLive.Index do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.Riders
  alias BikeBrigade.Riders.Rider
  alias BikeBrigade.Geocoder

  @impl true
  def mount(_params, session, socket) do
    if connected?(socket) do
      Riders.subscribe()
    end

    {:ok,
     socket
     |> assign_defaults(session)
     |> assign(:page, :riders)
     |> assign(:selected_rider, nil)
     |> assign(:located_place, nil)
     |> assign(:riders, fetch_riders())
     |> assign(:rider_query, "")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Rider")
    |> assign(:rider, Riders.get_rider!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Rider")
    |> assign(:rider, %Rider{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Riders")
    |> assign(:rider, nil)
  end

  @impl true
  def handle_event("locate-place", %{"query" => query}, socket) do
    {:ok, place} = Geocoder.lookup("#{query} Toronto Canada")

    {:noreply, assign(socket, located_place: place)}
  end

  @impl true
  def handle_event("select-rider", %{"id" => id}, socket) do
    selected_rider = Riders.get_rider!(id)
    # unselect if we click the same rider twice
    selected_rider =
      if selected_rider == socket.assigns.selected_rider, do: nil, else: selected_rider

    {:noreply, assign(socket, selected_rider: selected_rider)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    rider = Riders.get_rider!(id)
    {:ok, _} = Riders.delete_rider(rider)

    {:noreply, assign(socket, :riders, fetch_riders())}
  end

  @impl true
  def handle_event("search-riders", %{"value" => query}, socket) do
    {:noreply,
     socket
     |> assign(:selected_rider, nil)
     |> assign(:rider_query, query)
     |> assign(:riders, fetch_riders(query))}
  end

  @impl true
  def handle_info({:rider_updated, updated_rider}, socket) do
    {:noreply, assign(socket, :riders, [updated_rider])}
  end

  def handle_info({:rider_created, created_rider}, socket) do
    {:noreply, assign(socket, :riders, [created_rider])}
  end

  defp fetch_riders() do
    Riders.search_riders()
  end

  defp fetch_riders(query) do
    Riders.search_riders(query, email_search: true, phone_search: true)
  end
end
