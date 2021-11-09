defmodule BikeBrigadeWeb.Components.SlideoverComponent do
  use BikeBrigadeWeb, :live_component

  @impl Phoenix.LiveComponent
  def update(%{opts: opts} = assigns, socket) do
    {css, opts} = Keyword.pop(opts, :css, "max-w-2xl")

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:opts, opts)
     |> assign(:css, css)}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div id={@id}
      class="fixed inset-0 z-10 overflow-hidden"
      aria-labelledby="slide-over-title"
      role="dialog"
      aria-modal="true"
      phx-capture-click="close"
      phx-window-keydown="close"
      phx-key="escape"
      phx-target={"##{@id}"}
      phx-page-loading>
      <div class="absolute inset-0 overflow-hidden">
        <!-- Background overlay, show/hide based on slide-over state. -->
        <div class="absolute inset-0" aria-hidden="true">
          <div class="absolute inset-0 transition-opacity bg-gray-500 bg-opacity-75" aria-hidden="true"></div>
          <div class="fixed inset-y-0 right-0 flex max-w-full pl-10 sm:pl-16">
            <!--
              Slide-over panel, show/hide based on slide-over state.

              Entering: "transform transition ease-in-out duration-500 sm:duration-700"
                From: "translate-x-full"
                To: "translate-x-0"
              Leaving: "transform transition ease-in-out duration-500 sm:duration-700"
                From: "translate-x-0"
                To: "translate-x-full"
            -->
            <div class={"w-screen #{@css}"}>
              <div class="flex flex-col h-full py-6 overflow-y-scroll bg-white shadow-xl">
                <div class="px-4 sm:px-6">
                  <div class="flex items-start justify-between">
                    <h2 class="text-lg font-medium text-gray-900" id="slide-over-title">
                      <%= @title %>
                    </h2>
                    <div class="flex items-center ml-3 h-7">
                      <%= live_patch  to: @return_to, class: "text-gray-400 bg-white rounded-md hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500" do %>
                        <span class="sr-only">Close</span>
                        <%= Heroicons.Outline.x(class: "w-6 h-6") %>
                      <% end %>
                    </div>
                  </div>
                </div>
                <div class="relative flex-1 px-4 mt-6 sm:px-6">
                  <.live_component module={@component} {@opts} />
                </div>
              </div>
            </div>
          </div>
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
