defmodule BikeBrigade.Repo.Migrations.LeftJoinInRiderStats do
  use Ecto.Migration

  @view """
  create or replace view rider_stats as
  select
    riders.id as rider_id,
    count(tasks.id) as task_count,
    coalesce(sum(delivery_distance),0) as total_distance,
    count(distinct campaign_id) as campaign_count,
    count(distinct program_id) as program_count,
    (array_agg(campaign_id))[1] as latest_campaign_id

  from
    riders
  left join lateral
    (select
      tasks.id as id,
      tasks.delivery_distance as delivery_distance,
      campaigns.id as campaign_id,
      campaigns.program_id as program_id,
      tasks.assigned_rider_id as assigned_rider_id
    from
      tasks
    inner join
      campaigns
    on campaigns.id = tasks.campaign_id
    where
      tasks.assigned_rider_id = riders.id and
      campaigns.delivery_start <= NOW()::date + 1
    order by
      campaigns.delivery_start desc
  ) tasks
  on
    true
  group by
    riders.id;
  """

  def change do
    # removing since we load these views later
    # execute @view, "drop view rider_stats;"
  end
end
