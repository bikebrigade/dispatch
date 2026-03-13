defmodule BikeBrigade.Messaging.Slack do
  alias BikeBrigade.SlackApi
  alias BikeBrigade.Repo
  alias BikeBrigade.Delivery
  import BikeBrigade.Utils

  defmodule RiderSms do
    def post_message!(message) do
      payload = SlackApi.PayloadBuilder.build(get_config(:channel_id), message)
      :ok = SlackApi.post_message!(payload)
    end
  end

  defmodule Operations do
    def post_message!(message) do
      payload = SlackApi.PayloadBuilder.build(get_config(:channel_id), message)
      :ok = SlackApi.post_message!(payload)
    end
  end

  defmodule CampaignSummary do
    def send_campaign_summary(campaign) do
      {riders, tasks} = Delivery.campaign_riders_and_tasks(campaign)

      SlackApi.PayloadBuilder.build_delivery_summary(
        campaign.program.slack_channel_id,
        campaign,
        {riders, tasks}
      )
      |> SlackApi.post_message!()
    end
  end

  defmodule DeliveryNotes do
    import BikeBrigadeWeb.DeliveryHelpers, only: [campaign_name: 1]

    def post_message!(channel, message) do
      payload = SlackApi.PayloadBuilder.build(channel, message)
      :ok = SlackApi.post_message!(payload)
    end

    def notify_note_created!(delivery_note) do
      channel = get_channel_id(delivery_note)

      message = """
      📙 *New Delivery Note*
      *Rider:* #{delivery_note.rider.name}
      *Campaign:* #{campaign_name(delivery_note.task.campaign)}
      *Recipient:* #{delivery_note.task.dropoff_name}
      *Note:* #{delivery_note.note}
      """

      post_message!(channel, message)
    end

    def notify_note_resolved!(delivery_note, resolved_by) do
      channel = get_channel_id(delivery_note)

      message = """
      ✅ *Delivery Note Resolved*
      *Resolved by:* #{resolved_by.name}
      *Rider:* #{delivery_note.rider.name}
      *Campaign:* #{campaign_name(delivery_note.task.campaign)}
      *Recipient:* #{delivery_note.task.dropoff_name}
      *Note:* #{delivery_note.note}
      """

      post_message!(channel, message)
    end

    defp get_channel_id(delivery_note) do
      delivery_note =
        Repo.preload(delivery_note, [:rider, :resolved_by, task: [campaign: :program]])

      delivery_note.task.campaign.program.slack_channel_id || get_config(:channel_id)
    end
  end
end
