defmodule BikeBrigade.Repo.Migrations.RebuildCampaignStatsView do
  use Ecto.Migration

  import BikeBrigade.MigrationUtils

  def change do
    execute "drop view if exists campaign_stats", "drop view if exists campaign_stats"
    load_sql("campaign_stats_view.sql", "drop view if exists campaign_stats")
  end
end
