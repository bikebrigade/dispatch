defmodule BikeBrigade.Repo.Migrations.ReloadNeighborhoods do
  use Ecto.Migration

  def up do
    execute("TRUNCATE toronto_neighborhoods")

    flush()

    neighborhoods =
      :code.priv_dir(:bike_brigade)
      |> Path.join("repo/seeds/toronto_neighbourhoods.geojson")
      |> File.read!()
      |> Jason.decode!()

    name_overrides = %{
      "St Lawrence-East Bayfront-The Islands" => "St. Lawrence-East Bayfront"
    }

    entries =
      for neighborhood <- neighborhoods["features"] do
        name = neighborhood["properties"]["AREA_NAME"]

        %{
          neighborhood_id: String.to_integer(neighborhood["properties"]["AREA_SHORT_CODE"]),
          name: Map.get(name_overrides, name, name),
          geog: Geo.JSON.decode!(neighborhood["geometry"])
        }
      end

    BikeBrigade.Repo.insert_all("toronto_neighborhoods", entries)
  end

  def down do
    raise Ecto.MigrationError, "Reload neighborhoods migration is not reversible"
  end
end
