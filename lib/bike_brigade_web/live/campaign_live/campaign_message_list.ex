defmodule BikeBrigadeWeb.CampaignLive.CampaignMessageList do
  @moduledoc """
  This module handles the logic for showing a list of chat message
  with the riders for a specific campaign.
  """
  use BikeBrigadeWeb, :live_component

  alias BikeBrigade.Messaging

  import BikeBrigadeWeb.Components.SMSMessageListComponent

  alias BikeBrigadeWeb.Components.ConversationComponent

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    rider_ids =
      assigns.riders
      |> Map.values()
      |> Enum.map(& &1.id)

    conversations = Messaging.list_sms_conversations_for_riders(rider_ids)

    rider =
      cond do
        selected_rider = Map.get(assigns.riders, assigns.selected_rider_id) -> selected_rider
        Enum.count(conversations) == 0 -> nil
        [{selected_rider, _} | _] = conversations -> selected_rider
        true -> nil
      end

    {:ok,
     socket
     |> assign(:selected_rider, rider)
     |> assign(:live_action, assigns.live_action)
     |> stream(:conversations, conversations, dom_id: fn {rider, _} -> "conversation-list-item:#{rider.id}" end)
     |> assign(:current_user, assigns.current_user)
     |> assign(:campaign_id, assigns.campaign.id)}
  end
end
