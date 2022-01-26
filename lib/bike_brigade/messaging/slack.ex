defmodule BikeBrigade.Messaging.Slack do
  alias BikeBrigade.SlackApi

  defmodule RiderSms do
    @channel_id "C01QU0YVACW" #dispatch

    def post_message(message) do
      payload = SlackApi.PayloadBuilder.build(@channel_id, message)
      :ok = SlackApi.post_message(payload)
    end
  end

  defmodule Operations do
    @channel_id "C016VGHETS4" #software

    def post_message(message) do
      payload = SlackApi.PayloadBuilder.build(@channel_id, message)
      :ok = SlackApi.post_message(payload)
    end
  end
end
