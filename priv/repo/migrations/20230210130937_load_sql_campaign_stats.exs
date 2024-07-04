defmodule BikeBrigade.Repo.Migrations.CampaignStats do
  use Ecto.Migration

  def up do
    sql =
      Path.join(:code.priv_dir(:bike_brigade), "repo/sql/campaign_stats_20230210130937.sql")
      |> File.read!()

    execute(sql)
  end

  def down do
    sql = "drop view if exists campaign_stats"
    execute(sql)
  end
end
