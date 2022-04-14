defmodule BikeBrigadeWeb.StatsLive.NavComponent do
  use BikeBrigadeWeb, :live_component

  @impl Phoenix.LiveComponent
  def update(%{tab: selected_tab}, socket) do
    {:ok,
     socket
     |> assign(:class, &class(selected_tab, &1))
     |> assign(:svg_class, &svg_class(selected_tab, &1))}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="border-b border-gray-200">
      <nav class="flex -mb-px space-x-4" aria-label="Tabs">
        <%= live_redirect to: Routes.stats_dashboard_path(@socket, :show), class: @class.(:dashboard) do %>
          <Heroicons.Solid.chart_pie class={@svg_class.(:dashboard)} />
          <span>Dashboard</span>
        <% end %>

        <%= live_redirect to: Routes.stats_leaderboard_path(@socket, :show), class: @class.(:leaderboard) do %>
          <Heroicons.Solid.user_group class={@svg_class.(:leaderboard)} />
          <span>Leaderboard</span>
        <% end %>

        <a href="/analytics" target="_blank" class={@class.(:journal)}>
          <Heroicons.Solid.presentation_chart_line class={@svg_class.(:journal)} />
          <span class="mr-1">Analytics Dashboard</span>
          <span class="inline-flex items-center px-2.5 py-0.5 rounded-md text-sm font-medium bg-yellow-100 text-yellow-800">
            Beta
          </span>
        </a>
      </nav>
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
