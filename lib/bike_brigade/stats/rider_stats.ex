defmodule BikeBrigade.Stats.RiderStats do
  use BikeBrigade.Schema

  alias BikeBrigade.Riders.Rider
  alias BikeBrigade.Delivery.Program

  @primary_key false
  schema "rider_stats" do
    field :task_count, :integer, default: 0
    field :total_distance, :integer, default: 0
    field :campaign_count, :integer, default: 0
    field :program_count, :integer, default: 0

    belongs_to :rider, Rider
    belongs_to :program, Program
  end
end
