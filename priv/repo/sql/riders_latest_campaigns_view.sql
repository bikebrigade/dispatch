create
or replace view riders_latest_campaigns as
select
  rider_id,
  campaign_id
from
  (
    select
      campaigns_riders.rider_id as rider_id,
      campaigns.id as campaign_id,
      ROW_NUMBER() over (
        PARTITION BY campaigns_riders.rider_id
        ORDER BY
          campaigns.delivery_start DESC
      ) as row_number
    from
      campaigns_riders
      inner join campaigns on campaigns_riders.campaign_id = campaigns.id
  ) as result
where
  row_number = 1;