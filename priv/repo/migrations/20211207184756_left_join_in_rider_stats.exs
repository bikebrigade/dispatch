defmodule BikeBrigade.Repo.Migrations.LeftJoinInRiderStats do
  use Ecto.Migration

  @view """
  create or replace view rider_stats as
  select
    riders.id as rider_id,
    count(tasks.id) as task_count,
    coalesce(sum(delivery_distance),0) as total_distance,
    count(distinct campaign_id) as campaign_count,
    count(distinct program_id) as program_count
  from
    riders
  left join
    (select
      tasks.id as id,
      tasks.delivery_distance as delivery_distance,
      campaigns.id as campaign_id,
      campaigns.program_id as program_id,
      tasks.assigned_rider_id as assigned_rider_id
    from
      tasks
    inner join
      campaigns on campaigns.id = tasks.campaign_id
    where
    campaigns.delivery_start <= NOW()) tasks
  on tasks.assigned_rider_id = riders.id
  group by
    riders.id;
  """

  def change do
    execute @view, "drop view rider_stats;"
  end
end
