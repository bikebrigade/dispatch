defmodule BikeBrigadeWeb.MessagingHelpers do
  alias BikeBrigade.Messaging.SmsMessage

  alias BikeBrigadeWeb.CampaignHelpers

  defdelegate campaign_name(campaign), to: CampaignHelpers, as: :name
  defdelegate pickup_window(campaign, rider), to: CampaignHelpers

  def preview_message(%SmsMessage{body: body}) when not is_nil(body) do
    if String.length(body) > 30 do
      String.slice(body, 0, 30) <> "..."
    else
      body
    end
  end

  def preview_message(%SmsMessage{media: media}) when length(media) > 0 do
    "Attachment: #{length(media)} media"
  end

  def preview_message(_), do: "unknown message"

  def media_type(%SmsMessage.MediaItem{content_type: content_type}) do
    String.split(content_type, "/")
    |> List.first()
    |> String.to_atom()
  end
end
