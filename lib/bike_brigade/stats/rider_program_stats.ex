defmodule BikeBrigade.Stats.RiderProgramStats do
  use BikeBrigade.Schema

  alias BikeBrigade.Delivery.Program
  alias BikeBrigade.Riders.Rider

  @primary_key false
  schema "rider_program_stats" do
    field :task_count, :integer
    field :total_distance, :integer
    field :campaign_count, :integer

    belongs_to :program, Program
    belongs_to :rider, Rider
  end
end
