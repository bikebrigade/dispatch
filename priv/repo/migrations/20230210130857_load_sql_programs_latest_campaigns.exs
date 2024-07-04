defmodule BikeBrigade.Repo.Migrations.ProgramsLatestCampaigns do
  use Ecto.Migration

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
