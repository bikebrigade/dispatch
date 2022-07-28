defmodule BikeBrigadeWeb.Components.Sidebar do
  # TODO make this part of `use BikeBrigadeWeb, :component`
  use Phoenix.Component
  use Phoenix.HTML

  alias BikeBrigadeWeb.Router.Helpers, as: Routes

  def component(assigns) do
    ~H"""
    <div>
      <.sidebar_link
        selected={@current_page == :programs}
        to={Routes.program_index_path(@socket, :index)}
      >
        <:icon let={class}>
          <Heroicons.Outline.collection class={class} />
        </:icon>
        Programs
      </.sidebar_link>
      <.sidebar_link
        selected={@current_page == :campaigns}
        to={Routes.campaign_index_path(@socket, :index)}
      >
        <:icon let={class}>
          <Heroicons.Outline.cube class={class} />
        </:icon>
        Campaigns
      </.sidebar_link>
      <.sidebar_link
        selected={@current_page == :itinerary}
        to={Routes.itinerary_index_path(@socket, :index)}
      >
        <:icon let={class}>
          <Heroicons.Outline.clipboard_list class={class} />
        </:icon>
        My Itinerary
      </.sidebar_link>
      <.sidebar_link
        selected={@current_page == :opportunities}
        to={Routes.opportunity_index_path(@socket, :index)}
      >
        <:icon let={class}>
          <Heroicons.Outline.clipboard_list class={class} />
        </:icon>
        Opportunities
      </.sidebar_link>
      <.sidebar_link selected={@current_page == :riders} to={Routes.rider_index_path(@socket, :index)}>
        <:icon let={class}>
          <Heroicons.Outline.user_group class={class} />
        </:icon>
        Riders
      </.sidebar_link>
      <.sidebar_link
        selected={@current_page == :stats}
        to={Routes.stats_dashboard_path(@socket, :show)}
      >
        <:icon let={class}>
          <Heroicons.Outline.chart_bar class={class} />
        </:icon>
        Stats
      </.sidebar_link>
      <.sidebar_link
        selected={@current_page == :dispatchers}
        to={Routes.user_index_path(@socket, :index)}
      >
        <:icon let={class}>
          <Heroicons.Outline.users class={class} />
        </:icon>
        Dispatchers
      </.sidebar_link>
      <.sidebar_link
        selected={@current_page == :messages}
        to={Routes.sms_message_index_path(@socket, :index)}
      >
        <:icon let={class}>
          <Heroicons.Outline.chat class={class} />
        </:icon>
        Messages
      </.sidebar_link>
      <.sidebar_link
        selected={@current_page == :logout}
        to={Routes.authentication_path(@socket, :logout)}
        method={:post}
      >
        <:icon let={class}>
          <Heroicons.Outline.logout class={class} />
        </:icon>
        Log out
      </.sidebar_link>
    </div>
    """
  end

  defp sidebar_link(assigns) do
    class =
      if assigns.selected do
        "group flex items-center mb-1 px-2 py-2 text-base leading-6 font-medium text-gray-900 rounded-md bg-gray-100 focus:outline-none focus:bg-gray-200 transition ease-in-out duration-150"
      else
        "group flex items-center mb-1 px-2 py-2 text-base leading-6 font-medium text-gray-600 rounded-md hover:text-gray-900 hover:bg-gray-50 focus:outline-none focus:text-gray-900 focus:bg-gray-100 transition ease-in-out duration-150"
      end

    icon_class =
      if assigns.selected do
        "mr-4 w-6 h-6 text-gray-500 group-hover:text-gray-500 group-focus:text-gray-600 transition ease-in-out duration-150"
      else
        "mr-4 w-6 h-6 text-gray-400 group-hover:text-gray-500 group-focus:text-gray-500 transition ease-in-out duration-150"
      end

    assigns =
      assigns
      |> assign(:class, class)
      |> assign(:icon_class, icon_class)
      |> assign_new(:method, fn -> nil end)

    ~H"""
    <%= if @method do %>
      <%= link to: @to, class: @class, method: @method do %>
        <%= render_slot(@icon, @icon_class) %>
        <%= render_slot(@inner_block) %>
      <% end %>
    <% else %>
      <%= live_redirect to: @to, class: @class do %>
        <%= render_slot(@icon, @icon_class) %>
        <%= render_slot(@inner_block) %>
      <% end %>
    <% end %>
    """
  end
end
