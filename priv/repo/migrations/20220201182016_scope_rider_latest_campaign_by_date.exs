defmodule BikeBrigade.Repo.Migrations.ScopeRiderLatestCampaignByDate do
  use Ecto.Migration
  import BikeBrigade.Repo.Helpers

  def change do
    create_or_replace_view("riders_latest_campaigns", "riders_latest_campaigns_view.sql")
  end
end
