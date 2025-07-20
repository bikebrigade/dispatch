defmodule BikeBrigadeWeb.Layouts do
  use BikeBrigadeWeb, :html

  def rider_links() do
    [
      %{name: "Home", link: ~p"/home", icon: :home, current_page: :home},
      %{
        name: "Delivery Signup",
        link: ~p"/campaigns/signup",
        icon: :inbox,
        current_page: :campaigns_signup
      },
      %{name: "Itinerary", link: ~p"/itinerary", icon: :calendar_days, current_page: :itinerary},
      %{name: "Leaderboard", link: ~p"/leaderboard", icon: :trophy, current_page: :leaderboard},
      %{
        name: "Report a Bug",
        link: "https://form.jotform.com/241016644856054",
        icon: :bug_ant,
        current_page: nil
      }
    ]
  end

  embed_templates "layouts/*"

  attr :is_dispatcher, :boolean, default: false
  attr :is_rider, :boolean, default: false

  attr :current_page, :atom,
    values: [
      :programs,
      :campaigns,
      :opportunities,
      :riders,
      :stats,
      :users,
      :messages,
      :profile,
      :campaigns_signup,
      :leaderboard
    ]

  defp sidebar(assigns) do
    ~H"""
    <div>
      <div :if={@is_dispatcher} class="pb-2 mb-2 border-b border-gray-200 border-dashed">
        <.sidebar_link selected={@current_page == :programs} navigate={~p"/programs"}>
          <:icon>
            <Heroicons.inbox_stack />
          </:icon>
          Programs
        </.sidebar_link>
        <.sidebar_link selected={@current_page == :campaigns} navigate={~p"/campaigns"}>
          <:icon>
            <Heroicons.inbox />
          </:icon>
          Campaigns
        </.sidebar_link>
        <.sidebar_link selected={@current_page == :opportunities} navigate={~p"/opportunities"}>
          <:icon>
            <Heroicons.clipboard_document_check />
          </:icon>
          Opportunities
        </.sidebar_link>
        <.sidebar_link selected={@current_page == :riders} navigate={~p"/riders"}>
          <:icon>
            <Heroicons.user_group />
          </:icon>
          Riders
        </.sidebar_link>
        <.sidebar_link selected={@current_page == :stats} navigate={~p"/stats"}>
          <:icon>
            <Heroicons.chart_bar />
          </:icon>
          Stats
        </.sidebar_link>
        <.sidebar_link selected={@current_page == :users} navigate={~p"/users"}>
          <:icon>
            <Heroicons.users />
          </:icon>
          Users
        </.sidebar_link>
        <.sidebar_link selected={@current_page == :messages} navigate={~p"/messages"}>
          <:icon>
            <Heroicons.chat_bubble_oval_left_ellipsis />
          </:icon>
          Messages
        </.sidebar_link>
      </div>

      <.rider_links is_rider={@is_rider} is_dispatcher={@is_dispatcher} current_page={@current_page} />

      <div class="pb-2 mb-2">
        <.sidebar_link selected={@current_page == :profile} navigate={~p"/profile"}>
          <:icon>
            <Heroicons.user_circle />
          </:icon>
          My Profile
        </.sidebar_link>

        <.sidebar_link selected={@current_page == :logout} href={~p"/logout"} method="delete">
          <:icon>
            <Heroicons.arrow_left_on_rectangle solid />
          </:icon>
          Log out
        </.sidebar_link>
      </div>
    </div>
    """
  end

  @doc """
  Responsible for rendering the "rider" links, for dispatchers who are both riders and dispatchers.
  """
  def rider_links(%{is_dispatcher: true, is_rider: true} = assigns) do
    ~H"""
    <div class="mb-1 border border-gray-200 rounded-md">
      <.sidebar_section name="Rider Links">
        <:icon>
          <Heroicons.arrow_down solid />
        </:icon>
        <div :for={link <- rider_links()}>
          <.sidebar_link selected={@current_page == link.current_page} navigate={link.link}>
            <:icon>
              <BikeBrigadeWeb.Components.Icons.dynamic_icon name={link.icon} />
            </:icon>
            {link.name}
          </.sidebar_link>
        </div>
      </.sidebar_section>
    </div>
    """
  end

  def rider_links(%{is_dispatcher: true, is_rider: false} = assigns) do
    ~H"""
    <div></div>
    """
  end

  def rider_links(assigns) do
    ~H"""
    <div :for={link <- rider_links()}>
      <.sidebar_link selected={@current_page == link.current_page} navigate={link.link}>
        <:icon>
          <BikeBrigadeWeb.Components.Icons.dynamic_icon name={link.icon} />
        </:icon>
        {link.name}
      </.sidebar_link>
    </div>
    """
  end

  def sidebar_section(assigns) do
    ~H"""
    <div open class="rounded-md [&_.arrow-icon]:open:-rotate-180">
      <div class="flex items-center px-2 py-2 text-base font-medium leading-6 text-gray-600 transition duration-150 ease-in-out rounded-md select-none group focus:outline-none focus:text-gray-900 focus:bg-gray-100">
        {@name}
      </div>

      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :selected, :boolean
  attr :rest, :global, include: ~w(href patch navigate method)

  slot(:inner_block, required: true)
  slot(:icon, required: true)

  defp sidebar_link(%{selected: true} = assigns) do
    ~H"""
    <.link
      class="flex items-center px-2 py-2 mb-1 text-base font-medium leading-6 text-gray-900 transition duration-150 ease-in-out bg-gray-100 rounded-md group focus:outline-none focus:bg-gray-200"
      {@rest}
    >
      <span class="w-6 h-6 mr-4 text-gray-500 transition duration-150 ease-in-out group-hover:text-gray-500 group-focus:text-gray-600">
        {render_slot(@icon)}
      </span>
      {render_slot(@inner_block)}
    </.link>
    """
  end

  defp sidebar_link(%{selected: false} = assigns) do
    ~H"""
    <.link
      class="flex items-center px-2 py-2 mb-1 text-base font-medium leading-6 text-gray-600 transition duration-150 ease-in-out rounded-md group hover:text-gray-900 hover:bg-gray-50 focus:outline-none focus:text-gray-900 focus:bg-gray-100"
      {@rest}
    >
      <span class="w-6 h-6 mr-4 text-gray-400 transition duration-150 ease-in-out group-hover:text-gray-500 group-focus:text-gray-500">
        {render_slot(@icon)}
      </span>
      {render_slot(@inner_block)}
    </.link>
    """
  end

  defp open_mobile_menu() do
    JS.show(to: "#mobile-menu-container")
    |> JS.show(
      to: "#mobile-menu-backdrop",
      transition: {"transition-opacity ease-linear duration-300", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "#mobile-menu",
      display: "flex",
      transition:
        {"transition ease-in-out duration-300 transform", "-translate-x-full", "translate-x-0"}
    )
    |> JS.show(
      to: "#mobile-menu-close-button",
      transition: {"ease-in-out duration-300", "opacity-0", "opacity-100"}
    )
  end

  defp close_mobile_menu() do
    JS.hide(
      to: "#mobile-menu-backdrop",
      transition: {"transition-opacity ease-linear duration-300", "opacity-100", "opacity-0"},
      time: 300
    )
    |> JS.hide(
      to: "#mobile-menu",
      transition:
        {"transition ease-in-out duration-300 transform", "translate-x-0", "-translate-x-full"},
      time: 300
    )
    |> JS.hide(
      to: "#mobile-menu-close-button",
      transition: {"ease-in-out duration-300", "opacity-100", "opacity-0"},
      time: 300
    )
    |> JS.hide(to: "#mobile-menu-container", transition: {"", "", ""}, time: 300)
  end
end
