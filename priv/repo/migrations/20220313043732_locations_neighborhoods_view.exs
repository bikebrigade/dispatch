defmodule BikeBrigade.Repo.Migrations.LocationsNeighborhoodsView do
  use Ecto.Migration

  import BikeBrigade.MigrationUtils

  def change do
    load_sql("locations_neighborhoods_view.sql", "drop view if exists locations_neighborhoods")
  end
end
