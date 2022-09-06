defmodule BikeBrigadeWeb.RiderLive.TagsComponent do
  use BikeBrigadeWeb, :live_component

  alias BikeBrigade.Riders

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok,
     socket
     |> assign(:suggested_tags, [])}
  end

  @impl Phoenix.LiveComponent
  def handle_event("suggest", %{"value" => search}, socket) do
    suggested_tags =
      case String.length(search) do
        0 -> []
        _ -> Riders.search_tags(search, 10)
      end

    {:noreply,
     socket
     |> assign(:suggested_tags, suggested_tags)}
  end

  def handle_event("select", %{"name" => name}, socket) do
    %{tags: tags} = socket.assigns

    {:noreply,
     socket
     |> assign(:tags, tags ++ [name])
     |> assign(:suggested_tags, [])}
  end

  def handle_event("remove-tag", %{"index" => index}, socket) do
    index = String.to_integer(index)
    new_tags = List.delete_at(socket.assigns.tags, index)

    {:noreply,
     socket
     |> assign(:tags, new_tags)}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="block w-full px-3 py-2 my-1 border border-gray-300 rounded-md focus-within:outline-none focus-within:ring-1 focus-within:ring-blue-500 focus-within:border-blue-300">
      <%= for {tag, i} <- Enum.with_index(@tags) do %>
        <span class="my-0.5 inline-flex items-center px-2.5 py-1.5 rounded-md text-md font-medium bg-indigo-100 text-indigo-800 hover">
          <%= tag %>
          <Heroicons.Solid.x_circle
            class="w-5 h-5 ml-1 cursor-pointer"
            phx-click="remove-tag"
            phx-target={@myself}
            phx-value-index={i}
          />
        </span>
        <input type="hidden" name={@input_name} value={tag} />
      <% end %>
      <input
        form={"#{@id}-form"}
        id={"#{@id}-tag-input"}
        type="text"
        class="w-1/2 border-transparent appearance-none focus:border-transparent outline-transparent ring-transparent focus:ring-0"
        phx-hook="TagsComponentHook"
        phx-keyup="suggest"
        phx-target={@myself}
        autocomplete="off"
        phx-debounce="50"
        name="search"
        placeholder="Type to search or create tags"
      />
      <ul id="tag-selection-list" class="overflow-y-auto max-h-64">
        <%= for tag <- @suggested_tags do %>
          <li id={"tag-selection:#{tag.id}"} class="p-1">
            <a
              href="#"
              phx-click="select"
              phx-value-name={tag.name}
              phx-target={@myself}
              class="block transition duration-150 ease-in-out hover:bg-gray-50 focus:outline-none focus:bg-gray-50"
            >
              <p><%= tag.name %></p>
            </a>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end
end
