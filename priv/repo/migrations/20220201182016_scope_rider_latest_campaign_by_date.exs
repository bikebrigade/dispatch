defmodule BikeBrigade.Repo.Migrations.ScopeRiderLatestCampaignByDate do
  use Ecto.Migration

  # This migration was edited to use a SQL file from the future as we switch to
  # https://github.com/mveytsman/ecto_view_migrations
  def up do
    sql =
      Path.join(
        :code.priv_dir(:bike_brigade),
        "repo/sql/programs_latest_campaigns_20230210130857.sql"
      )
      |> File.read!()

    execute(sql)
  end

  def down do
    sql = "drop view if exists programs_latest_campaigns"
    execute(sql)
  end
end
