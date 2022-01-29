defmodule BikeBrigadeWeb.RiderLive.Show do
  use BikeBrigadeWeb, :live_view

  import Ecto.Query, warn: false

  alias BikeBrigade.Riders
  alias BikeBrigade.Stats.RiderStats

  alias BikeBrigade.LocalizedDateTime
  alias BikeBrigade.Repo

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page, :riders)}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id} = params, _url, socket) do
    rider =
      Riders.get_rider!(id)
      |> Repo.preload([
        :tags,
        :campaigns,
        :stats,
        program_stats: [:program],
        latest_campaign: [:program]
      ])

    today = LocalizedDateTime.today()
    yesterday = Date.add(today, -1)
    tomorrow = Date.add(today, 1)

    schedule = [
      {yesterday, Riders.list_campaigns_with_task_counts(rider, yesterday)},
      {today, Riders.list_campaigns_with_task_counts(rider, today)},
      {tomorrow, Riders.list_campaigns_with_task_counts(rider, tomorrow)}
    ]

    {:noreply,
     socket
     |> assign(:rider, rider)
     |> assign(:stats, rider.stats || %RiderStats{})
     |> assign(:today, today)
     |> assign(:schedule, schedule)
     |> apply_action(socket.assigns.live_action, params)}
  end

  @impl Phoenix.LiveView
  def handle_event("prev-week", _params, socket) do
    [{date, _}, _, _] = socket.assigns.schedule

    day1 = Date.add(date, -3)
    day2 = Date.add(date, -2)
    day3 = Date.add(date, -1)

    schedule = [
      {day1, Riders.list_campaigns_with_task_counts(socket.assigns.rider, day1)},
      {day2, Riders.list_campaigns_with_task_counts(socket.assigns.rider, day2)},
      {day3, Riders.list_campaigns_with_task_counts(socket.assigns.rider, day3)}
    ]

    {:noreply,
     socket
     |> assign(:schedule, schedule)}
  end

  def handle_event("next-week", _params, socket) do
    [_, _, {date, _}] = socket.assigns.schedule

    day1 = Date.add(date, 1)
    day2 = Date.add(date, 2)
    day3 = Date.add(date, 3)

    schedule = [
      {day1, Riders.list_campaigns_with_task_counts(socket.assigns.rider, day1)},
      {day2, Riders.list_campaigns_with_task_counts(socket.assigns.rider, day2)},
      {day3, Riders.list_campaigns_with_task_counts(socket.assigns.rider, day3)}
    ]

    {:noreply,
     socket
     |> assign(:schedule, schedule)}
  end

  defp apply_action(socket, :edit, _) do
    socket
    |> assign(:return_to, Routes.rider_show_path(socket, :show, socket.assigns.rider))
  end

  defp apply_action(socket, _, _), do: socket

  defp latest_campaign_info(assigns) do
    if assigns.rider.latest_campaign do
      ~H"""
      <%= link @rider.latest_campaign.program.name, to: Routes.campaign_show_path(@socket, :show, @rider.latest_campaign), class: "link" %> on <%= format_date(@rider.latest_campaign.delivery_start) %>
      """
    else
      ~H"Nothing (yet!)"
    end
  end
end
