create
or replace view campaign_stats as with campaign_rider_counts as (
  select
    campaigns_riders.campaign_id as campaign_id,
    count(campaigns_riders.id) as campaign_rider_count
  from
    campaigns_riders
  group by
    campaigns_riders.campaign_id
),
task_distances as (
  select
    tasks.*,
    st_distance(
      pickup_locations.coords,
      dropoff_locations.coords
    ) as distance
  from
    tasks
    left join locations pickup_locations on pickup_locations.id = tasks.pickup_location_id
    left join locations dropoff_locations on dropoff_locations.id = tasks.dropoff_location_id
)
select
  programs.id as program_id,
  campaigns.id as campaign_id,
  count(distinct campaigns.id) as campaign_count,
  count(tasks.id) as task_count,
  count(distinct tasks.assigned_rider_id) as assigned_rider_count,
  coalesce(
    sum(campaign_rider_counts.campaign_rider_count) :: integer,
    0
  ) as signed_up_rider_count,
  coalesce(sum(tasks.distance) :: integer, 0) as total_distance
from
  programs
  left join campaigns on campaigns.program_id = programs.id
  left join task_distances tasks on tasks.campaign_id = campaigns.id
  left join campaign_rider_counts on campaign_rider_counts.campaign_id = campaigns.id
group by
  ROLLUP(programs.id, campaigns.id);