defmodule BikeBrigade.Delivery.ProgramLatestCampaign do
  use BikeBrigade.Schema

  alias BikeBrigade.Delivery.{Program, Campaign}

  @primary_key false
  schema "programs_latest_campaigns" do
    belongs_to :program, Program, primary_key: true
    belongs_to :campaign, Campaign
  end
end
