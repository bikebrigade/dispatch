defmodule BikeBrigadeWeb.StatsLive.NavComponent do
  use BikeBrigadeWeb, :live_component

  @impl Phoenix.LiveComponent
  def update(%{tab: selected_tab}, socket) do
    {:ok,
     socket
     |> assign(:tab, selected_tab)
     |> assign(:class, &class(selected_tab, &1))
     |> assign(:svg_class, &svg_class(selected_tab, &1))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("navigate", %{"navigate" => to}, socket) do
    socket =
      case to do
        "dashboard" -> socket |> push_navigate(to: ~p"/stats")
        "leaderboard" -> socket |> push_navigate(to: ~p"/stats/leaderboard")
        "analytics-dashboard" -> socket |> push_navigate(to: "/analytics")
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="px-5 mb-4">
      <div class="sm:hidden">
        <label for="navigate" class="sr-only">Select a tab</label>
        <form phx-change={JS.push("navigate", target: @myself)}>
          <select
            id="navigate"
            name="navigate"
            class="block w-full py-2 pl-3 pr-10 text-base border-gray-300 rounded-md focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm"
          >
            <option value="dashboard" selected={@tab == :dashboard}>Dasboard</option>
            <option value="leaderboard" selected={@tab == :leaderboard}>Leaderboard</option>
            <option value="analytics-dashboard">Analytics Dashboard (beta)</option>
          </select>
        </form>
      </div>
      <div class="hidden mb-4 border-b border-gray-200 sm:block">
        <nav class="flex -mb-px space-x-4" aria-label="Tabs">
          <.link navigate={~p"/stats"} class={@class.(:dashboard)}>
            <Heroicons.chart_pie mini class={@svg_class.(:dashboard)} />
            <span>Dashboard</span>
          </.link>
          <.link navigate={~p"/stats/leaderboard"} class={@class.(:leaderboard)}>
            <Heroicons.user_group mini class={@svg_class.(:leaderboard)} />
            <span>Leaderboard</span>
          </.link>

          <.link href="/analytics" target="_blank" class={@class.(:journal)}>
            <Heroicons.presentation_chart_line mini class={@svg_class.(:journal)} />
            <span class="mr-1">Analytics Dashboard</span>
            <span class="hidden md:inline-flex items-center px-2.5 py-0.5 rounded-md text-sm font-medium bg-yellow-100 text-yellow-800">
              Beta
            </span>
          </.link>
        </nav>
      </div>
    </div>
    """
  end

  defp class(selected, link_to) do
    if selected == link_to do
      "inline-flex items-center px-1 py-4 text-sm font-medium text-gray-500 border-b-2 border-indigo-500 text-indigo-600 group"
    else
      "inline-flex items-center px-1 py-4 text-sm font-medium text-gray-500 border-b-2 text-gray-400 group-hover:text-gray-500 group"
    end
  end

  defp svg_class(selected, link_to) do
    if selected == link_to do
      "text-indigo-500 -ml-0.5 mr-2 h-5 w-5"
    else
      "text-gray-400 group-hover:text-gray-500 -ml-0.5 mr-2 h-5 w-5"
    end
  end
end
