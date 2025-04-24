defmodule BikeBrigadeWeb.AlertsLive.Index do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigadeWeb.Components.ConversationComponent
  alias BikeBrigade.{Presence, Messaging, Delivery, Riders, Riders.RiderSearch}

  import BikeBrigadeWeb.Components.SMSMessageListComponent
  import BikeBrigadeWeb.CampaignHelpers, only: [request_type: 1]

  alias BikeBrigadeWeb.CampaignHelpers
  defdelegate campaign_name(campaign), to: CampaignHelpers, as: :name
  defdelegate pickup_window(campaign, rider), to: CampaignHelpers

  @impl true
  def mount(_params, _session, socket) do
    banners = Messaging.list_banners()


    socket =
      socket
      |> assign(:page_title, "Alerts")
      |> assign(:page, :alerts)
      |> assign(:current_user, socket.assigns.current_user)
      |> assign(:banners, banners)

    {:ok, socket, temporary_assigns: [conversations: []]}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    banner = Messaging.new_banner()
    socket
    |> assign(:banner, banner)
    |> assign(:changeset, Messaging.banner_changeset(banner, %{}))
    |> assign(:page_title, "Create an Alert")
  end
  defp apply_action(socket, :edit, %{"id" => id}) do
    banner = Messaging.get_banner!(id)

    # TODO: need to break apart the DateTime to prefill the values of the edit form.
    socket
    |> assign(:page_title, "Edit Banner")
    |> assign(:changeset, Messaging.banner_changeset(banner, %{}))
    |> assign(:banner, banner)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "View Alerts")
  end
end
