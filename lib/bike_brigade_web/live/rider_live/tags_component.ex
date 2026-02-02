defmodule BikeBrigadeWeb.RiderLive.TagsComponent do
  use BikeBrigadeWeb, :live_component

  alias BikeBrigade.Riders

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok,
     socket
     |> assign(:suggested_tags, [])
     |> assign_new(:is_dispatcher, fn -> false end)
     |> assign_new(:restricted_tag_names, fn -> [] end)}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:is_dispatcher, fn -> false end)
      |> assign_new(:restricted_tag_names, fn -> [] end)

    %{tags: current_tags, is_dispatcher: is_dispatcher} = socket.assigns

    # Dispatchers see all tags, riders only see non-restricted
    suggested_tags =
      Riders.list_tags()
      |> Enum.reject(fn tag -> tag.name in current_tags end)
      |> then(fn tags ->
        if is_dispatcher, do: tags, else: Enum.reject(tags, & &1.restricted)
      end)

    {:ok, assign(socket, :suggested_tags, suggested_tags)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("select", %{"name" => name}, socket) do
    %{tags: tags, is_dispatcher: is_dispatcher, restricted_tag_names: restricted_tag_names} =
      socket.assigns

    new_tags = tags ++ [name]

    # Check if the selected tag is restricted and update the list
    selected_tag = Enum.find(socket.assigns.suggested_tags, &(&1.name == name))

    new_restricted_tag_names =
      if selected_tag && selected_tag.restricted do
        [name | restricted_tag_names]
      else
        restricted_tag_names
      end

    suggested_tags =
      Riders.list_tags()
      |> Enum.reject(fn tag -> tag.name in new_tags end)
      |> then(fn tags ->
        if is_dispatcher, do: tags, else: Enum.reject(tags, & &1.restricted)
      end)

    {:noreply,
     socket
     |> assign(:tags, new_tags)
     |> assign(:restricted_tag_names, new_restricted_tag_names)
     |> assign(:suggested_tags, suggested_tags)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("remove_tag", %{"index" => index}, socket) do
    %{tags: tags, is_dispatcher: is_dispatcher, restricted_tag_names: restricted_tag_names} =
      socket.assigns

    tag_name = Enum.at(tags, index)

    # Riders can't remove restricted tags
    if !is_dispatcher && tag_name in restricted_tag_names do
      {:noreply, socket}
    else
      new_tags = List.delete_at(tags, index)

      suggested_tags =
        Riders.list_tags()
        |> Enum.reject(fn tag -> tag.name in new_tags end)
        |> then(fn tags ->
          if is_dispatcher, do: tags, else: Enum.reject(tags, & &1.restricted)
        end)

      {:noreply,
       socket
       |> assign(:tags, new_tags)
       |> assign(:suggested_tags, suggested_tags)}
    end
  end

  defp visible_selected_tags(tags, restricted_tag_names, is_dispatcher) do
    tags
    |> Enum.with_index()
    |> Enum.map(fn {name, index} ->
      %{name: name, index: index, restricted: name in restricted_tag_names}
    end)
    |> Enum.filter(fn tag -> is_dispatcher || !tag.restricted end)
  end

  attr :tag, :map, required: true
  attr :input_name, :string, required: true
  attr :target, :any, required: true

  defp selected_tag(assigns) do
    ~H"""
    <span class="my-0.5 inline-flex items-center px-2.5 py-1.5 rounded-md text-md font-medium bg-indigo-100 text-indigo-800">
      {@tag.name}
      <Heroicons.lock_closed :if={@tag.restricted} mini class="w-4 h-4 ml-1 text-amber-600" />
      <Heroicons.x_circle
        solid
        class="w-5 h-5 ml-1 cursor-pointer"
        phx-click={JS.push("remove_tag", value: %{index: @tag.index}, target: @target)}
      />
    </span>
    <input type="hidden" name={@input_name} value={@tag.name} />
    """
  end

  attr :tag, :map, required: true
  attr :target, :any, required: true

  defp suggested_tag(assigns) do
    ~H"""
    <span
      class={[
        "my-0.5 inline-flex items-center px-2.5 py-1.5 rounded-md text-md font-medium cursor-pointer hover:bg-gray-200",
        if(@tag.restricted, do: "bg-gray-200 text-gray-500", else: "bg-gray-100 text-gray-500")
      ]}
      phx-click={JS.push("select", value: %{name: @tag.name}, target: @target)}
    >
      <Heroicons.plus mini class="w-4 h-4 mr-1" />
      {@tag.name}
      <Heroicons.lock_closed :if={@tag.restricted} mini class="w-4 h-4 ml-1 text-amber-600" />
    </span>
    """
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <div class="flex flex-wrap gap-1 w-full px-3 py-2 my-1 border border-gray-300 rounded-md">
        <.selected_tag
          :for={tag <- visible_selected_tags(@tags, @restricted_tag_names, @is_dispatcher)}
          tag={tag}
          input_name={@input_name}
          target={@myself}
        />
        <.suggested_tag :for={tag <- @suggested_tags} tag={tag} target={@myself} />
      </div>
      <.link :if={@is_dispatcher} navigate={~p"/tags"} class="text-sm text-gray-500 hover:text-gray-700">
        Manage tags
      </.link>
    </div>
    """
  end
end
