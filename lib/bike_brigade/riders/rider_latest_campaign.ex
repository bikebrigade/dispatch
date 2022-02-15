defmodule BikeBrigade.Riders.RiderLatestCampaign do
  use BikeBrigade.Schema

  alias BikeBrigade.Riders.Rider
  alias BikeBrigade.Delivery.Campaign

  @primary_key false
  schema "riders_latest_campaigns" do
    belongs_to :rider, Rider, primary_key: true
    belongs_to :campaign, Campaign
  end
end
