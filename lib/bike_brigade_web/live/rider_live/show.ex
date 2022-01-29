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
  def handle_params(%{"id" => id}, _url, socket) do
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
     |> assign(:schedule, schedule)}
  end

  @impl Phoenix.LiveView
  def handle_event("prev-day", _params, socket) do
    [{date, _} = s1, s2, _] = socket.assigns.schedule

    prev = Date.add(date, -1)

    scheudle = [
      {prev, Riders.list_campaigns_with_task_counts(socket.assigns.rider, prev)},
      s1,
      s2
    ]

    {:noreply,
     socket
     |> assign(:schedule, scheudle)}
  end

  def handle_event("next-day", _params, socket) do
    [_, s1, {date, _} = s2] = socket.assigns.schedule

    next = Date.add(date, 1)

    scheudle = [
      s1,
      s2,
      {next, Riders.list_campaigns_with_task_counts(socket.assigns.rider, next)}
    ]

    {:noreply,
     socket
     |> assign(:schedule, scheudle)}
  end

  defp apply_action(socket, :edit, _) do
    socket
    |> assign(:return_to, Routes.rider_show_path(socket, :show, socket.assigns.rider))
  end

  defp apply_action(socket, _, _), do: socket

  defp latest_campaign_info(assigns) do
    if assigns.rider.latest_campaign do
      ~H"""
      <%= link @rider.latest_campaign.program.name, to: Routes.campaign_show_path(@socket, :show, @rider.latest_campaign), class: "link" %> on <%= LocalizedDateTime.to_date(@rider.latest_campaign.delivery_start) %>
      """
    else
      ~H"Nothing (yet!)"
    end
  end
end
