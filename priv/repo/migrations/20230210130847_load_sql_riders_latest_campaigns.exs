defmodule BikeBrigade.Repo.Migrations.RidersLatestCampaigns do
  use Ecto.Migration
  def up do
    sql = Path.join(:code.priv_dir(:bike_brigade), "repo/sql/riders_latest_campaigns_20230210130847.sql") |> File.read!()
    execute(sql)
  end

  def down do
    sql = "drop view if exists riders_latest_campaigns"
    execute(sql)
  end
end
