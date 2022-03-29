defmodule BikeBrigade.Stats.CampaignStats do
  use BikeBrigade.Schema

  alias BikeBrigade.Riders.Rider
  alias BikeBrigade.Delivery.Program

  @primary_key false
  schema "campaign_stats" do
    field :task_count, :integer, default: 0
    field :rider_count, :integer, default: 0
    field :total_distance, :integer, default: 0
    field :campaign_count, :integer, default: 0

    belongs_to :campaign, Rider
    belongs_to :program, Program
  end
end
