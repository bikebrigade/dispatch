defmodule BikeBrigadeWeb.Components.ModalComponent do
  use BikeBrigadeWeb, :live_component

  @impl Phoenix.LiveComponent
  def update(%{opts: opts} = assigns, socket) do
    {css, opts} = Keyword.pop(opts, :css, "sm:max-w-2xl")

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:opts, opts)
     |> assign(:css, css)}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div id={@id} class="fixed inset-0 z-10 overflow-y-auto"
        phx-capture-click="close"
        phx-window-keydown="close"
        phx-key="escape"
        phx-target={"##{@id}"}
        phx-page-loading>
      <div class="flex items-end justify-center min-h-screen px-4 pt-4 pb-20 text-center sm:block sm:p-0">
        <!--
          Background overlay, show/hide based on modal state.

          Entering: "ease-out duration-300"
            From: "opacity-0"
            To: "opacity-100"
          Leaving: "ease-in duration-200"
            From: "opacity-100"
            To: "opacity-0"
        -->
        <div class="fixed inset-0 transition-opacity" aria-hidden="true">
          <div class="absolute inset-0 bg-gray-500 opacity-75"></div>
        </div>

        <!--
          Modal panel, show/hide based on modal state.

          Entering: "ease-out duration-300"
            From: "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
            To: "opacity-100 translate-y-0 sm:scale-100"
          Leaving: "ease-in duration-200"
            From: "opacity-100 translate-y-0 sm:scale-100"
            To: "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
        -->
        <div class={"#{@css} inline-block px-4 pt-5 pb-4 overflow-hidden text-left align-bottom transition-all transform bg-white rounded-lg shadow-xl sm:my-8 sm:align-middle sm:w-full sm:p-6"} role="dialog" aria-modal="true" aria-labelledby="modal-headline">
          <div class="absolute top-0 right-0 pt-4 pr-4">
            <%= live_patch  to: @return_to, class: "block text-gray-400 bg-white rounded-md hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500" do %>
              <span class="sr-only">Close</span>
              <%= Heroicons.Outline.x(class: "w-6 h-6") %>
            <% end %>
          </div>
          <.live_component module={@component} {@opts} />
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("close", _, socket) do
    {:noreply, push_patch(socket, to: socket.assigns.return_to)}
  end
end
