defmodule BikeBrigade.Repo.Migrations.CreateRiderProgramStatsView do
  use Ecto.Migration

  # @view """
  # create or replace view rider_program_stats as
  # select
  #   assigned_rider_id as rider_id,
  #   program_id,
  #   count(tasks.id) as task_count,
  #   sum(delivery_distance) as total_distance,
  #   count(distinct campaigns.id) as campaign_count
  # from
  #   tasks
  # left join
  #   campaigns on campaigns.id = tasks.campaign_id
  # where
  #   campaigns.delivery_start <= NOW()
  # group by
  #   assigned_rider_id, program_id;
  # """

  def change do
    # removing since we load these views later
    # execute @view, "drop view rider_program_stats;"
  end
end
