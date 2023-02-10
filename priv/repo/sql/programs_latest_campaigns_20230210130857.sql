create
or replace view programs_latest_campaigns as
select
  program_id,
  campaign_id
from
  (
    select
      campaigns.program_id as program_id,
      campaigns.id as campaign_id,
      ROW_NUMBER() over (
        PARTITION BY campaigns.program_id
        ORDER BY
          campaigns.delivery_start DESC
      ) as row_number
    from
      campaigns
  ) as result
where
  row_number = 1;