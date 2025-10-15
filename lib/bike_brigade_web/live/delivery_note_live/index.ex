defmodule BikeBrigadeWeb.DeliveryNoteLive.Index do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.Delivery

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page, :delivery_notes)
     |> assign(:page_title, "Delivery Notes")
     |> assign(:delivery_notes, list_delivery_notes())}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl Phoenix.LiveView
  def handle_event("resolve", %{"id" => id}, socket) do
    delivery_note = Delivery.get_delivery_note!(id)
    user = socket.assigns.current_user

    case Delivery.resolve_delivery_note(delivery_note, user.id) do
      {:ok, _delivery_note} ->
        {:noreply,
         socket
         |> put_flash(:info, "Delivery note marked as resolved")
         |> assign(:delivery_notes, list_delivery_notes())}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to resolve delivery note")}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("unresolve", %{"id" => id}, socket) do
    delivery_note = Delivery.get_delivery_note!(id)

    case Delivery.unresolve_delivery_note(delivery_note) do
      {:ok, _delivery_note} ->
        {:noreply,
         socket
         |> put_flash(:info, "Delivery note marked as unresolved")
         |> assign(:delivery_notes, list_delivery_notes())}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to unresolve delivery note")}
    end
  end

  defp apply_action(socket, :index, _params) do
    socket
  end

  defp list_delivery_notes do
    Delivery.list_delivery_notes(preload: [:rider, :task, :resolved_by])
  end
end
