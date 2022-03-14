create
or replace view campaigns_latest_sms_messages as
select
  campaign_id,
  sms_message_id
from
  (
    select
      sms_messages.campaign_id as campaign_id,
      sms_messages.id as sms_message_id,
      ROW_NUMBER() over (
        PARTITION BY sms_messages.campaign_id
        ORDER BY
          sms_messages.sent_at DESC
      ) as row_number
    from
      sms_messages
  ) as result
where
  row_number = 1;