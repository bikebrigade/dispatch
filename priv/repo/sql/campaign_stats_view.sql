create
or replace view campaign_stats as
select
  campaigns.program_id as program_id, -- useful if we ever need program stats
  campaigns.id as campaign_id,
  count(distinct campaigns.id) as campaign_count, -- useful if we ever need program stats
  count(tasks.id) as task_count,
  count(distinct tasks.assigned_rider_id) as rider_count,
  sum(delivery_distance) as total_distance
from
  tasks
  left join campaigns on campaigns.id = tasks.campaign_id
where
  tasks.assigned_rider_id IS NOT NULL
  and campaigns.delivery_start <= NOW()
group by
  ROLLUP(program_id, campaigns.id)