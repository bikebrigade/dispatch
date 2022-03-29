create
or replace view campaign_stats as
select
  programs.id as program_id,
  campaigns.id as campaign_id,
  count(distinct campaigns.id) as campaign_count, -- useful if we ever need program stats
  count(tasks.id) as task_count,
  count(distinct tasks.assigned_rider_id) as rider_count,
  sum(delivery_distance) as total_distance
from
  programs
  left join campaigns on campaigns.program_id = programs.id
  left join tasks on tasks.campaign_id = campaigns.id
group by
  ROLLUP(programs.id, campaigns.id)