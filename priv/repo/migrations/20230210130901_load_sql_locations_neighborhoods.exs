defmodule BikeBrigade.Repo.Migrations.LocationsNeighborhoods do
  use Ecto.Migration

  def up do
    sql =
      Path.join(
        :code.priv_dir(:bike_brigade),
        "repo/sql/locations_neighborhoods_20230210130901.sql"
      )
      |> File.read!()

    execute(sql)
  end

  def down do
    sql = "drop view if exists locations_neighborhoods"
    execute(sql)
  end
end
