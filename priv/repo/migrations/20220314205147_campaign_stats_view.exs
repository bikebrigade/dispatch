defmodule BikeBrigade.Repo.Migrations.CampaignStatsView do
  use Ecto.Migration
  import BikeBrigade.MigrationUtils

  def change do
    load_sql("campaign_stats_view.sql", "drop view if exists campaign_stats")
  end
end
