defmodule BikeBrigade.Stats.CampaignStats do
  use BikeBrigade.Schema

  alias BikeBrigade.Delivery.{Campaign, Program}

  @primary_key false
  schema "campaign_stats" do
    field :task_count, :integer, default: 0
    field :assigned_rider_count, :integer, default: 0
    field :signed_up_rider_count, :integer, default: 0
    field :total_distance, :integer, default: 0
    field :campaign_count, :integer, default: 0

    belongs_to :campaign, Campaign
    belongs_to :program, Program
  end
end
