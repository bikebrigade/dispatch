defmodule BikeBrigade.Repo.Migrations.ReloadViewsFromFiles do
  use Ecto.Migration
  import BikeBrigade.MigrationUtils

  def change do
    execute "drop view if exists rider_stats", ""
    load_sql("rider_stats_view.sql", "drop view if exists rider_stats")
    load_sql("rider_program_stats_view.sql", "drop view if exists rider_program_stats")
    load_sql("riders_latest_campaigns_view.sql", "drop view if exists riders_latest_campaigns")
  end
end
