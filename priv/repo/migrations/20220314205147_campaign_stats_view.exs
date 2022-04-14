defmodule BikeBrigade.Repo.Migrations.CampaignStatsView do
  use Ecto.Migration
  import BikeBrigade.MigrationUtils

  def change do
     # removing since we load these views later
    # load_sql("campaign_stats_view.sql", "drop view if exists campaign_stats")
  end
end
