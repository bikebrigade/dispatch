defmodule BikeBrigadeWeb.RiderLive.Show do
  use BikeBrigadeWeb, :live_view

  import Ecto.Query, warn: false

  alias BikeBrigade.Riders
  alias BikeBrigade.Stats.RiderStats

  alias BikeBrigade.LocalizedDateTime
  alias BikeBrigade.Repo

  import BikeBrigadeWeb.CampaignHelpers

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page, :riders)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl Phoenix.LiveView
  def handle_event("prev-schedule", %{"period" => period}, socket) do
    [{date, _}, _, _] = socket.assigns.schedule

    period = String.to_integer(period)
    day1 = Date.add(date, -period)
    day2 = Date.add(date, -period + 1)
    day3 = Date.add(date, -period + 2)

    schedule = [
      {day1, Riders.list_campaigns_with_task_counts(socket.assigns.rider, day1)},
      {day2, Riders.list_campaigns_with_task_counts(socket.assigns.rider, day2)},
      {day3, Riders.list_campaigns_with_task_counts(socket.assigns.rider, day3)}
    ]

    {:noreply,
     socket
     |> assign(:schedule, schedule)}
  end

  def handle_event("next-schedule", %{"period" => period}, socket) do
    [_, _, {date, _}] = socket.assigns.schedule

    period = String.to_integer(period)
    day1 = Date.add(date, period - 2)
    day2 = Date.add(date, period - 1)
    day3 = Date.add(date, period)

    schedule = [
      {day1, Riders.list_campaigns_with_task_counts(socket.assigns.rider, day1)},
      {day2, Riders.list_campaigns_with_task_counts(socket.assigns.rider, day2)},
      {day3, Riders.list_campaigns_with_task_counts(socket.assigns.rider, day3)}
    ]

    {:noreply,
     socket
     |> assign(:schedule, schedule)}
  end

  defp apply_action(socket, :profile, _params) do
    if socket.assigns.current_user.rider_id do
      socket
      |> assign(:page_title, "Profile")
      |> assign(:page, :profile)
      |> assign_rider(socket.assigns.current_user.rider_id)
    else
      socket
      |> put_flash(:error, "You must be registered as a Rider to edit your profile")
      |> push_redirect(to: "/")
    end
  end

  defp apply_action(socket, :edit_profile, _params) do
    socket
    |> assign(:page_title, "Edit Profile")
    |> assign(:page, :profile)
    |> assign(
      :return_to,
      Routes.rider_show_path(socket, :profile)
    )
    |> assign_rider(socket.assigns.current_user.rider_id)
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    socket
    |> assign_rider(id)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(
      :return_to,
      Routes.rider_show_path(socket, :show, id)
    )
    |> assign_rider(id)
  end

  defp apply_action(socket, _, _), do: socket

  defp assign_rider(socket, id) do
    rider =
      Riders.get_rider!(id)
      |> Repo.preload([
        :location,
        :tags,
        :campaigns,
        :total_stats,
        :user,
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

    socket
    |> assign(:rider, rider)
    |> assign(:stats, rider.total_stats || %RiderStats{})
    |> assign(:today, today)
    |> assign(:schedule, schedule)
  end

  defp latest_campaign_info(assigns) do
    if assigns.rider.latest_campaign do
      ~H"""
      <%= link(@rider.latest_campaign.program.name,
        to: Routes.campaign_show_path(@socket, :show, @rider.latest_campaign),
        class: "link"
      ) %> on <%= format_date(@rider.latest_campaign.delivery_start) %>
      """
    else
      ~H"Nothing (yet!)"
    end
  end
end
