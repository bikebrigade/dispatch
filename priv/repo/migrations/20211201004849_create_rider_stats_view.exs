defmodule BikeBrigade.Repo.Migrations.CreateRiderStatsView do
  use Ecto.Migration

  # @view """
  # create or replace view rider_stats as
  # select
  #   assigned_rider_id as rider_id,
  #   count(tasks.id) as task_count,
  #   sum(delivery_distance) as total_distance,
  #   count(distinct campaigns.id) as campaign_count,
  #   count(distinct program_id) as program_count
  # from
  #   tasks
  # left join
  #   campaigns on campaigns.id = tasks.campaign_id
  # where
  #   campaigns.delivery_start <= NOW()
  # group by
  #   assigned_rider_id;
  # """

  def change do
    # removing since we load these views later
    # execute @view, "drop view rider_stats;"
  end
end
