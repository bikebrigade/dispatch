defmodule BikeBrigadeWeb.StatsLive.Dashboard do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.Stats

  alias BikeBrigadeWeb.StatsLive.NavComponent

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {total_riders, active_riders} = Stats.rider_counts()

    {:ok,
     socket
     |> assign(:page, :stats)
     |> assign(:page_title, "Stats")
     |> assign(:total_riders, total_riders)
     |> assign(:active_riders, active_riders)
     |> assign_stats(:week)}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("select-period", %{"period" => period}, socket)
      when period in ~w(day week month) do
    {:noreply,
     socket
     |> assign_stats(String.to_atom(period))}
  end

  def label_period(date, :day) do
    Calendar.strftime(date, "%a %b %-d")
  end

  def label_period(date, :week) do
    {first, last} = {Date.beginning_of_week(date), Date.end_of_week(date)}
    "#{Calendar.strftime(first, "%b %-d")} - #{Calendar.strftime(last, "%b %-d %Y")}"
  end

  def label_period(date, :month) do
    {first, last} = {Date.beginning_of_month(date), Date.end_of_month(date)}
    "#{Calendar.strftime(first, "%b %-d")} - #{Calendar.strftime(last, "%b %-d %Y")}"
  end

  defp assign_stats(socket, period) when period in [:day, :week, :month] do
    stats = Stats.rider_stats(period)

    {labels, new_riders, returning_riders, riders} =
      stats
      |> Enum.reduce(
        {[], [], [], []},
        fn {date, period_stats}, {labels, new_riders, returning_riders, riders} ->
          {[label_period(date, period) | labels], [period_stats[:new_riders] | new_riders],
           [period_stats[:returning_riders] | returning_riders], [period_stats[:riders] | riders]}
        end
      )

    last_period = %{
      label: List.first(labels),
      new_riders: List.first(new_riders),
      returning_riders: List.first(returning_riders),
      total_riders: List.first(riders)
    }

    dataset = %{
      labels: Enum.reverse(labels),
      datasets: [
        %{
          label: "New Riders",
          data: Enum.reverse(new_riders),
          borderColor: "#66c2a5",
          backgroundColor: "#66c2a5"
        },
        %{
          label: "Returning Riders",
          data: Enum.reverse(returning_riders),
          borderColor: "#fc8d62",
          backgroundColor: "#fc8d62"
        },
        %{
          label: "Total Riders",
          data: Enum.reverse(riders),
          borderColor: "#8da0cb",
          backgroundColor: "#8da0cb"
        }
      ]
    }

    socket
    |> assign(:period, period)
    |> assign(:last_period, last_period)
    |> push_event("update-chart", dataset)
  end
end
