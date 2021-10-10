defmodule BikeBrigade.Messaging.SlackWebhook do
  alias BikeBrigade.SlackApi
  alias BikeBrigade.Messaging.SmsMessage
  alias BikeBrigadeWeb.Router.Helpers, as: Routes
  alias BikeBrigadeWeb.Endpoint

  def post_message(%SmsMessage{rider: rider} = message) do
    text = "*#{rider.name}*: #{filter_mrkdwn(message.body)}"

    payload =
      %{
        blocks: [
          %{
            type: "section",
            text: %{
              type: "mrkdwn",
              text: text
            },
            accessory: %{
              type: "button",
              text: %{
                type: "plain_text",
                text: "Reply",
                emoji: true
              },
              url: Routes.sms_message_index_url(Endpoint, :show, rider.id)
            }
          }
          | for m <- message.media do
              %{
                type: "image",
                image_url: m.url,
                alt_text: "Rider sent us media"
              }
            end
        ]
      }
      |> Jason.encode!()

    :ok = SlackApi.send_webook(payload)
  end

  def filter_mrkdwn(nil) do
    ""
  end

  def filter_mrkdwn(str) do
    str
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end
end
