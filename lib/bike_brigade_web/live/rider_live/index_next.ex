defmodule BikeBrigadeWeb.RiderLive.IndexNext do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.Repo
  alias BikeBrigade.Riders
  alias BikeBrigade.Delivery
  alias BikeBrigade.LocalizedDateTime

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:riders, fetch_riders())
     |> assign(:page, :riders)}
  end

  defp fetch_riders() do
    Riders.search_riders()
    |> Repo.preload(:tags)
  end

  defp latest_campaign_date(assigns) do
    assigns = assign(assigns, :date, Delivery.latest_campaign_date(assigns.rider))
    ~H"""
    <%= if @date do %>
      <%=  @date |> LocalizedDateTime.to_date() |> Calendar.strftime("%b %-d, %Y") %>
    <% end %>
    """
  end

  def render(assigns) do
    ~H"""
    <div>
      <UI.table rows={@riders}>
        <:th>
          Name
        </:th>
        <:th>
          Location
        </:th>
        <:th>
          Tags
        </:th>
        <:th>
          Last Active
        </:th>

        <:td let={rider}>
          <%= live_redirect to: Routes.rider_show_path(@socket, :show, rider), class: "link" do %>
            <%= rider.name %><span class="ml-1 text-xs lowercase ">(<%= rider.pronouns %>)</span>
          <% end %>
        </:td>
        <:td let={rider}>
          <%= rider.location_struct.neighborhood %>
        </:td>
        <:td let={rider}>
          <%= rider.tags |> Enum.map(& &1.name) |> Enum.join(",") %>
        </:td>
        <:td let={rider}>
          <.latest_campaign_date rider={rider}/>
        </:td>
      </UI.table>
    </div>
    """
  end
end
