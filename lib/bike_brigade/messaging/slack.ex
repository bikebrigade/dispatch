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
end
