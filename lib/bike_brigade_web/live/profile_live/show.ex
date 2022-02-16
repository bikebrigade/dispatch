defmodule BikeBrigadeWeb.ProfileLive.Show do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.Stats.RiderStats

  alias BikeBrigade.Repo

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    rider =
      socket.assigns.current_user.rider
      |> Repo.preload([
        :tags,
        :campaigns,
        :total_stats,
        program_stats: [:program],
        latest_campaign: [:program]
      ])

    {:ok,
     socket
     |> assign(:page, :profile)
     |> assign(:stats, rider.total_stats || %RiderStats{})
     |> assign(:rider, rider)}
  end

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
