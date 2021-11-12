defmodule BikeBrigadeWeb.Components.UI do
  use Phoenix.Component
  use Phoenix.HTML
  alias Phoenix.LiveView.JS

  def slideover(assigns) do
    width_css = if assigns[:wide], do: "max-w-4xl", else: "max-w-2xl"
    opts = assigns_to_attributes(assigns, [:width])

    assigns =
      assigns
      |> assign(:width_css, width_css)
      |> assign_new(:title, fn -> nil end)
      |> assign(:opts, opts)

    ~H"""
    <div id={@id} class="fixed inset-0 z-10 overflow-hidden" aria-labelledby="slide-over-title" role="dialog" aria-modal="true">
      <div class="absolute inset-0 overflow-hidden">
        <!--
          Background overlay, show/hide based on slide-over state.

          Entering: "ease-in-out duration-500"
            From: "opacity-0"
            To: "opacity-100"
          Leaving: "ease-in-out duration-500"
            From: "opacity-100"
            To: "opacity-0"
        -->
        <div class="absolute inset-0 transition-opacity bg-gray-500 bg-opacity-75 slideover-overlay" aria-hidden="true"></div>

        <div class="fixed inset-y-0 right-0 flex max-w-full pl-10">
          <!--
            Slide-over panel, show/hide based on slide-over state.

            Entering: "transform transition ease-in-out duration-500 sm:duration-700"
              From: "translate-x-full"
              To: "translate-x-0"
            Leaving: "transform transition ease-in-out duration-500 sm:duration-700"
              From: "translate-x-0"
              To: "translate-x-full"
          -->
          <div class={"w-screen #{width_css} slideover-panel"}
              phx-window-keydown={hide_slideover(@id)} phx-key="escape"
              phx-click-away={hide_slideover(@id)}>
            <div class="flex flex-col h-full py-6 overflow-y-scroll bg-white shadow-xl">
              <div class="px-4 sm:px-6">
                <div class="flex items-start justify-between">
                  <h2 class="text-lg font-medium text-center text-gray-900" id="slide-over-title">
                    <%= render_slot @title %>
                  </h2>
                  <div class="flex items-center ml-3 h-7">
                    <%= live_patch "close", to: @return_to, data: [modal_return: true], class: "hidden" %>
                    <button type="button" phx-click={hide_slideover(@id)} class="text-gray-400 bg-white rounded-md hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                      <span class="sr-only">Close panel</span>
                      <!-- Heroicon name: outline/x -->
                      <svg class="w-6 h-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" aria-hidden="true">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                      </svg>
                    </button>
                  </div>
                </div>
              </div>
              <div class="relative flex-1 px-4 mt-6 sm:px-6">
                <%= render_slot @inner_block %>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def hide_slideover(js \\ %JS{}, id) do
    js
    |> JS.hide(to: "##{id}", transition: "", time: 500)
    |> JS.hide(
      to: "##{id} .slideover-panel",
      transition:
        {"transform transition ease-in-out duration-500", "translate-x-0", "translate-x-full"},
      time: 500
    )
    |> JS.hide(
      to: "##{id} .slideover-overlay",
      transition: {"ease-in-out duration-500", "opacity-100", "opacity-0"},
      time: 500
    )
    |> JS.dispatch("click", to: "##{id} [data-modal-return]")
  end

  def show_slideover(js \\ %JS{}, id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.transition(
      {"transform transition ease-in-out duration-500", "translate-x-0", "translate-x-full"},
      to: "##{id} .slideover-panel",
      time: 500
    )

    # |> JS.transition( {"ease-in-out duration-500", "opacity-0", "opacity-100"},
    #  to: "##{id} .slideover-overlay",
    #  time: 500
    # )
  end

  def show_modal(js \\ %JS{}, id) do
    js
    |> JS.show(
      to: "##{id}",
      display: "inline-block",
      transition: {"ease-out duration-1000", "opacity-0", "opacity-100"},
      time: 1000
    )
    |> JS.show(
      to: "##{id} .modal-content",
      display: "inline-block",
      transition:
        {"ease-out duration-300", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.remove_class("fade-in", to: "##{id}")
    |> JS.hide(
      to: "##{id}",
      transition: {"ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> JS.hide(
      to: "##{id} .modal-content",
      transition:
        {"ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
    |> JS.dispatch("click", to: "##{id} [data-modal-return]")
  end

  def modal(assigns) do
    assigns =
      assigns
      |> assign_new(:show, fn -> false end)
      |> assign_new(:title, fn -> [] end)
      |> assign_new(:return_to, fn -> nil end)

    ~H"""
    <div id={@id} class={"fixed z-10 inset-0 overflow-y-auto #{if @show, do: "fade-in", else: "hidden"}"} aria-labelledby="modal-title" role="dialog" aria-modal="true">
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
        <div
          class={"#{if @show, do: "fade-in-scale", else: "hidden"} modal-content inline-block align-bottom bg-white rounded-lg px-4 pt-5 pb-4 text-left overflow-hidden shadow-xl transform sm:my-8 sm:align-middle sm:max-w-2xl sm:w-full sm:p-6"}
          phx-window-keydown={hide_modal(@id)} phx-key="escape"
          phx-click-away={hide_modal(@id)}
        >
          <%= if @return_to do %>
          <div class="absolute top-0 right-0 pt-4 pr-4">
            <%= live_patch "close", to: @return_to, data: [modal_return: true], class: "hidden" %>
            <button type="button" phx-click={hide_modal(@id)}  class="block text-gray-400 bg-white rounded-md hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
              <span class="sr-only">Close</span>
              <Heroicons.Outline.x class="w-6 h-6" />
            </button>
          </div>
          <% end %>
          <div class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left">
            <h2 class="my-3 text-2xl font-extrabold leading-9 text-center text-gray-900">
              <%= render_slot(@title) %>
            </h2>
            <div class="mt-2">
              <%= render_slot(@inner_block) %>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
