defmodule BikeBrigadeWeb.Components.UserSelectionComponent do
  use BikeBrigadeWeb, :live_component

  alias BikeBrigade.Accounts

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok,
     socket
     |> assign(:selected_user, nil)
     |> assign(:search, nil)
     |> assign(:users, [])}
  end

  @impl Phoenix.LiveComponent
  def update(%{selected_user_id: selected_user_id} = assigns, socket)
      when not is_nil(selected_user_id) do
    user = Accounts.get_user(selected_user_id)

    {:ok,
     socket
     |> assign(Map.delete(assigns, :selected_user_id))
     |> assign(:selected_user, user)}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns |> Map.delete(:selected_user_id))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("suggest", %{"value" => search}, socket) do
    {:noreply, assign(socket, :users, Accounts.search_users(search))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("unselect", _params, socket) do
    {
      :noreply,
      socket
      |> assign(:search, socket.assigns.selected_user.name)
      |> assign(:selected_user, nil)
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event("select", %{"id" => id}, socket) do
    user = Accounts.get_user(id)

    {:noreply,
     socket
     |> assign(:selected_user, user)
     |> assign(:users, [])}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <%= if @selected_user do %>
        <a
          href="#"
          phx-click="unselect"
          phx-target={@myself}
          class="block transition duration-150 ease-in-out hover:bg-gray-50 focus:outline-none focus:bg-gray-50"
        >
          <div class="flex items-center px-4 py-4 sm:px-6">
            <div class="flex items-center flex-1 min-w-0">
              <div class="flex-shrink-0">
                <img class="w-12 h-12 rounded-full" src={gravatar(@selected_user.email)} alt="" />
              </div>
              <div class="flex-1 min-w-0 px-4 md:grid md:grid-cols-2 md:gap-4">
                <div>
                  <div class="text-sm font-medium leading-5 text-indigo-600 truncate">
                    <%= @selected_user.name %>
                  </div>
                  <div class="flex items-center mt-2 text-sm leading-5 text-gray-500">
                    <svg
                      class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400"
                      viewBox="0 0 20 20"
                      fill="currentColor"
                    >
                      <path d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z">
                      </path>
                    </svg>
                    <span class="truncate">
                      <%= @selected_user.phone %>
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </a>
        <input type="hidden" name={@input_name} value={@selected_user.id} />
      <% else %>
        <input
          phx-keyup="suggest"
          phx-target={@myself}
          phx-debounce="50"
          name="search"
          type="text"
          placeholder="Type to search for users by name"
          class="block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5"
        />
        <ul id="user-selection-list" class="overflow-y-auto max-h-64">
          <%= for user <- @users do %>
            <li id={"user-selection:#{user.id}"}>
              <a
                href="#"
                phx-click="select"
                phx-value-id={user.id}
                phx-target={@myself}
                class="block transition duration-150 ease-in-out hover:bg-gray-50 focus:outline-none focus:bg-gray-50"
              >
                <div class="flex items-center px-4 py-4 sm:px-6">
                  <div class="flex items-center flex-1 min-w-0">
                    <div class="flex-shrink-0">
                      <img class="w-12 h-12 rounded-full" src={gravatar(user.email)} alt="" />
                    </div>
                    <div class="flex-1 min-w-0 px-4 md:grid md:grid-cols-2 md:gap-4">
                      <div>
                        <div class="text-sm font-medium leading-5 text-indigo-600 truncate">
                          <%= user.name %>
                        </div>
                        <div class="flex items-center mt-2 text-sm leading-5 text-gray-500">
                          <svg
                            class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400"
                            viewBox="0 0 20 20"
                            fill="currentColor"
                          >
                            <path d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z">
                            </path>
                          </svg>
                          <span class="truncate">
                            <%= user.phone %>
                          </span>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </a>
            </li>
          <% end %>
        </ul>
      <% end %>
    </div>
    """
  end
end
