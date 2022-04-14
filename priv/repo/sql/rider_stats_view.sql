create
or replace view rider_stats as
select
  assigned_rider_id as rider_id,
  program_id,
  count(tasks.id) as task_count,
  sum(st_distance(pickup_locations.coords, dropoff_locations.coords))::integer as total_distance,
  count(distinct campaigns.id) as campaign_count,
  count(distinct program_id) as program_count
from
  tasks
  left join campaigns on campaigns.id = tasks.campaign_id
  left join locations pickup_locations on pickup_locations.id = tasks.pickup_location_id
  left join locations dropoff_locations on dropoff_locations.id = tasks.dropoff_location_id
where
  tasks.assigned_rider_id IS NOT NULL
  and campaigns.delivery_start <= NOW()
group by
  ROLLUP(assigned_rider_id, program_id)