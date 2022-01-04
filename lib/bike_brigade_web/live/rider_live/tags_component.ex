defmodule BikeBrigadeWeb.RiderLive.TagsComponent do
  use BikeBrigadeWeb, :live_component

  alias BikeBrigade.Riders
  alias BikeBrigade.Riders.Tag
  alias BikeBrigade.Repo

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok,
     socket
     |> assign(:suggested_tags, [])}
  end

  @impl Phoenix.LiveComponent
  def handle_event("suggest", %{"value" => search, "key" => "Enter"}, socket) do
    %{tags: tags} = socket.assigns

    tag = Riders.find_or_create_tag(search)

    {:noreply,
    socket
    |> assign(:tags, tags ++ [tag])
    |> assign(:suggested_tags, [])}
  end

  @impl Phoenix.LiveComponent
  def handle_event("suggest", %{"value" => search, "key" => key}, socket) do
    suggested_tags = case String.length(search) do
      0 -> []
      _ -> Riders.search_tags(search, 10)
    end

    {:noreply,
     socket
     |> assign(:suggested_tags, suggested_tags)}
  end

  def handle_event("select", %{"id" => id}, socket) do
    %{tags: tags} = socket.assigns

    tag = Tag |> Repo.get(id)

    {:noreply,
     socket
     |> assign(:tags, tags ++ [tag])
     |> assign(:suggested_tags, [])}
  end

  def handle_event("remove-tag", %{"index" => index}, socket) do
    index = String.to_integer(index)
    new_tags = List.delete_at(socket.assigns.tags, index)
    {:noreply,
     socket
     |> assign(:tags, new_tags)}
  end

  def render(assigns) do
    ~H"""
    <div class="block w-full px-3 py-2 my-1 border border-gray-300 rounded-md">
      <%= for {tag, i} <- Enum.with_index(@tags) do %>
        <span class="inline-flex items-center px-2.5 py-1.5 rounded-md text-md font-medium bg-indigo-100 text-indigo-800 hover">
        <%= tag.name %>
        <Heroicons.Outline.x_circle class="w-5 h-5 ml-1 cursor-pointer" phx-click="remove-tag" phx-target={@myself} phx-value-index={i} />
        </span>
        <input type="hidden" name={@input_name} value={tag.name}>
      <% end  %>
      <input class="border-transparent appearance-none focus:border-transparent outline-transparent ring-transparent focus:ring-0" type="text" phx-keyup="suggest" phx-target={ @myself } phx-debounce="50" name="search" placeholder="Type to search for tags">
      <ul id="tag-selection-list" class="overflow-y-auto max-h-64">
        <%= for tag <- @suggested_tags do %>
          <li id={"tag-selection:#{tag.id}"} class="p-1">
            <a href="#" phx-click="select" phx-value-id={ tag.id } phx-target={ @myself } class="block transition duration-150 ease-in-out hover:bg-gray-50 focus:outline-none focus:bg-gray-50">
              <p><%= tag.name %></p>
            </a>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end
end
