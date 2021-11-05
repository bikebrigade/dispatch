defmodule BikeBrigadeWeb.ItemLive.Index do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.Delivery
  alias BikeBrigade.Delivery.Item

  @impl true
  def mount(_params, session, socket) do
    {:ok,
     socket
     |> assign_defaults(session)
     |> assign(:page, :programs)
     |> assign(:page_title, "Programs")
     |> assign(:items, list_items())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Item")
    |> assign(:item, Delivery.get_item!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Item")
    |> assign(:item, %Item{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Items")
    |> assign(:item, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    item = Delivery.get_item!(id)
    {:ok, _} = Delivery.delete_item(item)

    {:noreply, assign(socket, :items, list_items())}
  end

  defp list_items do
    Delivery.list_items()
  end
end
