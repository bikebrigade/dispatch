defmodule BikeBrigadeWeb.RiderLive.TagsComponent do
  use BikeBrigadeWeb, :live_component

  def handle_event("remove-tag", %{"index" => index}, socket) do
    index = String.to_integer(index)
    new_tags = List.delete_at(socket.assigns.tags, index)
    {:noreply,
     socket
     |> assign(:tags, new_tags)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <%= for {tag, i} <- Enum.with_index(@tags) do %>
        <span class="inline-flex items-center px-2.5 py-1.5 rounded-md text-md font-medium bg-indigo-100 text-indigo-800 hover">
        <%= tag.name %>
        <Heroicons.Outline.x_circle class="w-5 h-5 ml-1 cursor-pointer" phx-click="remove-tag" phx-target={@myself} phx-value-index={i} />
        </span>
        <input type="hidden" name={@input_name} value={tag.name}>
      <% end  %>
      <input type="text">
    </div>
    """
  end
end
