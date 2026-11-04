defmodule BikeBrigade.Repo.Migrations.EnforceTaskCampaignRiderAssignment do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO campaigns_riders (
      campaign_id,
      rider_id,
      rider_capacity,
      enter_building,
      token,
      rider_signed_up,
      backup_rider,
      inserted_at,
      updated_at
    )
    SELECT DISTINCT
      tasks.campaign_id,
      tasks.assigned_rider_id,
      1,
      FALSE,
      md5(
        'campaign-rider-assignment-backfill:' ||
        tasks.campaign_id::text || ':' || tasks.assigned_rider_id::text
      ),
      FALSE,
      FALSE,
      NOW(),
      NOW()
    FROM tasks
    LEFT JOIN campaigns_riders
      ON campaigns_riders.campaign_id = tasks.campaign_id
      AND campaigns_riders.rider_id = tasks.assigned_rider_id
    WHERE tasks.campaign_id IS NOT NULL
      AND tasks.assigned_rider_id IS NOT NULL
      AND campaigns_riders.id IS NULL
    """)

    execute("""
    ALTER TABLE tasks
    ADD CONSTRAINT tasks_campaign_rider_fkey
    FOREIGN KEY (campaign_id, assigned_rider_id)
    REFERENCES campaigns_riders (campaign_id, rider_id)
    """)
  end

  def down do
    execute("ALTER TABLE tasks DROP CONSTRAINT tasks_campaign_rider_fkey")
  end
end
