defmodule BikeBrigade.Delivery.CampaignLatestMessage do
  use BikeBrigade.Schema

  alias BikeBrigade.Delivery.Campaign
  alias BikeBrigade.Messaging.SmsMessage

  @primary_key false
  schema "campaigns_latest_sms_messages" do
    belongs_to :campaign, Campaign, primary_key: true
    belongs_to :sms_message, SmsMessage
  end
end
