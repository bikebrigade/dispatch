defmodule BikeBrigade.Repo.Migrations.CampaignsLatestMessagesView do
  use Ecto.Migration
  import BikeBrigade.MigrationUtils

  def change do
    load_sql("campaigns_latest_sms_messages_view.sql", "drop view if exists campaigns_latest_sms_messages")
  end
end
