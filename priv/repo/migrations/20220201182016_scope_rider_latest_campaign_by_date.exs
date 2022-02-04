defmodule BikeBrigade.Repo.Migrations.ScopeRiderLatestCampaignByDate do
  use Ecto.Migration
  import BikeBrigade.MigrationUtils

  def change do
    load_sql("riders_latest_campaigns_view.sql")
  end
end
