defmodule BikeBrigadeWeb.RiderLive.IndexNext do
  use BikeBrigadeWeb, :live_view

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
          <%= rider.name %>
        </:td>
        <:td let={rider}>
          <%= rider.name %>
        </:td>
        <:td let={rider}>
          <%= rider.name %>
        </:td>
        <:td let={rider}>
          <%= if Delivery.latest_campaign_date(rider), do: BikeBrigade.LocalizedDateTime.to_date(Delivery.latest_campaign_date(rider)), else: ""
          # %>
        </:td>
      </UI.table>
    </div>
    """
  end
end
