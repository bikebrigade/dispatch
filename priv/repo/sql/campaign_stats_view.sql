create
or replace view campaign_stats as
select
  programs.id as program_id,
  campaigns.id as campaign_id,
  count(distinct campaigns.id) as campaign_count,
  count(tasks.id) as task_count,
  count(distinct tasks.assigned_rider_id) as assigned_rider_count,
  count(distinct campaigns_riders.rider_id) as signed_up_rider_count,
  sum(st_distance(pickup_locations.coords, dropoff_locations.coords))::integer as total_distance
from
  programs
  left join campaigns on campaigns.program_id = programs.id
  left join tasks on tasks.campaign_id = campaigns.id
  left join campaigns_riders on campaigns_riders.campaign_id = campaigns.id
  left join locations pickup_locations on pickup_locations.id = tasks.pickup_location_id
  left join locations dropoff_locations on dropoff_locations.id = tasks.dropoff_location_id
group by
  ROLLUP(programs.id, campaigns.id);