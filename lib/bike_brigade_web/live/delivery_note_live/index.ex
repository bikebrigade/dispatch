defmodule BikeBrigadeWeb.DeliveryNoteLive.Index do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.Delivery

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Delivery.subscribe()
    end

    delivery_notes = list_delivery_notes()
    {unresolved_notes, resolved_notes} = Enum.split_with(delivery_notes, &is_nil(&1.resolved_at))

    {:ok,
     socket
     |> assign(:page, :delivery_notes)
     |> assign(:page_title, "Delivery Notes")
     |> assign(:unresolved_count, length(unresolved_notes))
     |> assign(:resolved_count, length(resolved_notes))
     |> stream(:unresolved_notes, unresolved_notes)
     |> stream(:resolved_notes, resolved_notes)}
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
      {:ok, updated_note} ->
        {:noreply,
         socket
         |> put_flash(:info, "Delivery note marked as resolved")
         |> update(:unresolved_count, &(&1 - 1))
         |> update(:resolved_count, &(&1 + 1))
         |> stream_delete(:unresolved_notes, updated_note)
         |> stream_insert(:resolved_notes, updated_note, at: 0)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to resolve delivery note")}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("unresolve", %{"id" => id}, socket) do
    delivery_note = Delivery.get_delivery_note!(id)

    case Delivery.unresolve_delivery_note(delivery_note) do
      {:ok, updated_note} ->
        {:noreply,
         socket
         |> put_flash(:info, "Delivery note marked as unresolved")
         |> update(:unresolved_count, &(&1 + 1))
         |> update(:resolved_count, &(&1 - 1))
         |> stream_delete(:resolved_notes, updated_note)
         |> stream_insert(:unresolved_notes, updated_note, at: 0)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to unresolve delivery note")}
    end
  end

  defp apply_action(socket, :index, _params) do
    socket
  end

  @impl Phoenix.LiveView
  def handle_info({:delivery_note_created, delivery_note}, socket) do
    # New notes are always unresolved
    {:noreply,
     socket
     |> update(:unresolved_count, &(&1 + 1))
     |> stream_insert(:unresolved_notes, delivery_note, at: 0)}
  end

  @impl Phoenix.LiveView
  def handle_info({:delivery_note_updated, delivery_note}, socket) do
    # Update the note in the appropriate stream based on its resolution status
    if is_nil(delivery_note.resolved_at) do
      {:noreply, stream_insert(socket, :unresolved_notes, delivery_note)}
    else
      {:noreply, stream_insert(socket, :resolved_notes, delivery_note)}
    end
  end

  defp list_delivery_notes do
    Delivery.list_delivery_notes(preload: [:rider, :task, :resolved_by])
  end
end
