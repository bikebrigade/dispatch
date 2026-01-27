defmodule BikeBrigadeWeb.TagLive.Index do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.Riders
  alias BikeBrigade.Riders.Tag

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page, :tags)
     |> assign(:tags, list_tags())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Tag")
    |> assign(:tag, Riders.get_tag!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Tag")
    |> assign(:tag, %Tag{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Tags")
    |> assign(:tag, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    tag = Riders.get_tag!(id)
    {:ok, _} = Riders.delete_tag(tag)

    {:noreply, assign(socket, :tags, list_tags())}
  end

  def handle_event("toggle_restricted", %{"id" => id}, socket) do
    tag = Riders.get_tag!(id)
    {:ok, _} = Riders.toggle_tag_restricted(tag)

    {:noreply, assign(socket, :tags, list_tags())}
  end

  defp list_tags do
    Riders.list_tags_with_rider_count()
  end
end
