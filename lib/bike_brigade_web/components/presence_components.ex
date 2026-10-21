defmodule BikeBrigadeWeb.Components.PresenceComponents do
  @moduledoc "Shows which other dispatchers are on the same page."
  use BikeBrigadeWeb, :html

  @doc "A floating badge listing the other dispatchers viewing this page."
  attr :others_present, :list, required: true

  def currently_viewing(assigns) do
    ~H"""
    <div
      :if={!Enum.empty?(@others_present)}
      class="fixed top-0 right-0 z-10 flex-col items-end hidden mt-2 mr-2 sm:flex"
    >
      <div
        id="currently-viewing"
        class="hidden w-64 bg-white border border-gray-200 shadow sm:rounded-lg"
      >
        <div class="px-2 py-3 bg-white border-b border-gray-200 sm:rounded-t-lg">
          <div class="absolute top-0 right-0 pt-4 pr-4 sm:block">
            <button
              phx-click={JS.hide(to: "#currently-viewing") |> JS.show(to: "#currently-viewing-close")}
              type="button"
              class="block text-gray-400 bg-white rounded-md hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              <span class="sr-only">Close</span>
              <Heroicons.x_mark solid class="w-6 h-6" />
            </button>
          </div>
          <div class="flex flex-wrap items-center">
            <h3 class="text-lg font-medium leading-6 text-gray-900">
              {Enum.count(@others_present)} Currently Viewing
            </h3>
          </div>
        </div>
        <ul class="px-2 py-3">
          <%= for user <- @others_present
          do %>
            <li>{user.name}</li>
          <% end %>
        </ul>
      </div>

      <div id="currently-viewing-close">
        <.button
          phx-click={JS.hide(to: "#currently-viewing-close") |> JS.show(to: "#currently-viewing")}
          type="button"
          color={:white}
          rounded={:full}
        >
          <Heroicons.eye solid class="w-5 h-5" />
          <span class="ml-1 text-sm font-semibold">{Enum.count(@others_present)}</span>
        </.button>
      </div>
    </div>
    """
  end
end
