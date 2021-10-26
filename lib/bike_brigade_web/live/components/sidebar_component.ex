defmodule BikeBrigadeWeb.Components.SidebarComponent do
  use BikeBrigadeWeb, :live_component

  @impl Phoenix.LiveComponent
  def update(%{page: selected_page}, socket) do
    {:ok,
     socket
     |> assign(:class, &class(selected_page, &1))
     |> assign(:svg_class, &svg_class(selected_page, &1))}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
    <%= live_patch to: Routes.program_index_path(@socket, :index), class: @class.(:programs) do %>
      <%= Heroicons.Outline.collection(class: @svg_class.(:programs)) %>
      Programs
    <% end %>
    <%= live_patch to: Routes.campaign_index_path(@socket, :index), class: @class.(:campaigns) do %>
      <%= Heroicons.Outline.cube(class: @svg_class.(:campaigns)) %>
      Campaigns
    <% end %>
    <%= live_patch to: Routes.opportunity_index_path(@socket, :index), class: @class.(:opportunities) do %>
      <%= Heroicons.Outline.clipboard_list(class: @svg_class.(:riders)) %>
      Signups
    <% end %>
    <%= live_patch to: Routes.rider_index_path(@socket, :index), class: @class.(:riders) do %>
      <%= Heroicons.Outline.user_group(class: @svg_class.(:riders)) %>
      Riders
    <% end %>
    <%= live_patch to: Routes.stats_dashboard_path(@socket, :show), class: @class.(:stats) do %>
      <%= Heroicons.Outline.chart_bar(class: @svg_class.(:stats)) %>
      Stats
    <% end %>
    <%= live_patch to: Routes.user_index_path(@socket, :index), class: @class.(:dispatchers) do %>
      <%= Heroicons.Outline.users(class: @svg_class.(:dispatchers)) %>
      Dispatchers
    <% end %>
    <%= live_patch to: Routes.sms_message_index_path(@socket, :index), class: @class.(:messages) do %>
      <%= Heroicons.Outline.chat(class: @svg_class.(:messages)) %>
      Messages
    <% end %>
    <%= link to: Routes.authentication_path(@socket, :logout), method: :post, class: @class.(:logout) do %>
      <%= Heroicons.Outline.logout(class: @svg_class.(:logout)) %>
      Log out
    <% end %>
    </div>
    """
  end

  defp class(selected, link_to) do
    if selected == link_to do
      "group flex items-center mb-1 px-2 py-2 text-base leading-6 font-medium text-gray-900 rounded-md bg-gray-100 focus:outline-none focus:bg-gray-200 transition ease-in-out duration-150"
    else
      "group flex items-center mb-1 px-2 py-2 text-base leading-6 font-medium text-gray-600 rounded-md hover:text-gray-900 hover:bg-gray-50 focus:outline-none focus:text-gray-900 focus:bg-gray-100 transition ease-in-out duration-150"
    end
  end

  def svg_class(selected, link_to) do
    if selected == link_to do
      "mr-4 h-6 w-6 text-gray-500 group-hover:text-gray-500 group-focus:text-gray-600 transition ease-in-out duration-150"
    else
      "mr-4 h-6 w-6 text-gray-400 group-hover:text-gray-500 group-focus:text-gray-500 transition ease-in-out duration-150"
    end
  end
end
