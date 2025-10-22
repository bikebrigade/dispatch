defmodule BikeBrigade.Messaging.Slack do
  alias BikeBrigade.SlackApi
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

  defmodule DeliveryNotes do
    import BikeBrigadeWeb.DeliveryHelpers, only: [campaign_name: 1]
    def post_message!(message) do
      payload = SlackApi.PayloadBuilder.build(get_config(:channel_id), message)
      :ok = SlackApi.post_message!(payload)
    end

    def notify_note_created!(delivery_note) do
      message = """
      📙 *New Delivery Note*
      *Rider:* #{delivery_note.rider.name}
      *Campaign:* #{campaign_name(delivery_note.task.campaign)}
      *Recipient:* #{delivery_note.task.dropoff_name}
      *Note:* #{delivery_note.note}
      """

      post_message!(message)
    end

    def notify_note_resolved!(delivery_note, resolved_by) do
      message = """
      ✅ *Delivery Note Resolved*
      *Resolved by:* #{resolved_by.name}
      *Rider:* #{delivery_note.rider.name}
      *Campaign:* #{campaign_name(delivery_note.task.campaign)}
      *Recipient:* #{delivery_note.task.dropoff_name}
      *Note:* #{delivery_note.note}
      """

      post_message!(message)
    end
  end
end
