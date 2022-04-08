create
or replace view campaign_stats as
select
  campaigns.id as campaign_id,
  coalesce(tasks.count, 0) as task_count,
  coalesce(tasks.assigned_rider_count, 0) as assigned_rider_count,
  coalesce(signed_up_riders.count, 0) as signed_up_rider_count,
  coalesce(tasks.total_distance, 0) as total_distance
from
  campaigns
  left join (
    select
      campaign_id,
      count(campaigns_riders.id)
    from
      campaigns_riders
    group by
      campaigns_riders.campaign_id
  ) signed_up_riders on signed_up_riders.campaign_id = campaigns.id
  left join (
    select
      campaign_id,
      count(tasks.id),
      count(distinct tasks.assigned_rider_id) as assigned_rider_count,
      sum(
        st_distance(
          pickup_locations.coords,
          dropoff_locations.coords
        )
      ) :: integer as total_distance
    from
      tasks
      left join locations pickup_locations on pickup_locations.id = tasks.pickup_location_id
      left join locations dropoff_locations on dropoff_locations.id = tasks.dropoff_location_id
    group by
      tasks.campaign_id
  ) tasks on tasks.campaign_id = campaigns.id;