defmodule BikeBrigade.SlackApi.PayloadBuilder do
  alias BikeBrigade.Messaging.SmsMessage
  use Phoenix.VerifiedRoutes, endpoint: BikeBrigadeWeb.Endpoint, router: BikeBrigadeWeb.Router

  def build(channel_id, %SmsMessage{rider: rider} = message) do
    text =
      "<#{url(~p"/riders/#{rider}")}|*#{rider.name}*>: #{filter_mrkdwn(message.body)}"

    %{
      channel: channel_id,
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
            url: url(~p"/messages/#{rider}")
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
  end

  def build(channel_id, message) do
    %{
      channel: channel_id,
      blocks: [
        %{
          type: "section",
          text: %{
            type: "mrkdwn",
            text: message
          }
        }
      ]
    }
    |> Jason.encode!()
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
