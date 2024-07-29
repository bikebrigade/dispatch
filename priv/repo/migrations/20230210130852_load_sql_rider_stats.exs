defmodule BikeBrigade.Repo.Migrations.RiderStats do
  use Ecto.Migration

  def up do
    sql =
      Path.join(:code.priv_dir(:bike_brigade), "repo/sql/rider_stats_20230210130852.sql")
      |> File.read!()

    execute(sql)
  end

  def down do
    sql = "drop view if exists rider_stats"
    execute(sql)
  end
end
