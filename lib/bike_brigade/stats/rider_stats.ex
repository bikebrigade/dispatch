defmodule BikeBrigade.Stats.RiderStats do
  use BikeBrigade.Schema

  alias BikeBrigade.Riders.Rider

  @primary_key false
  schema "rider_stats" do
    field :task_count, :integer
    field :total_distance, :integer
    field :campaign_count, :integer
    field :program_count, :integer

    belongs_to :rider, Rider
  end
end
