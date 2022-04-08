defmodule BikeBrigade.Repo.Migrations.Neighborhoods do
  use Ecto.Migration

  def up do
    create table(:toronto_neighborhoods) do
      add :neighborhood_id, :integer
      add :name, :string
      add :geog, :geography
    end

    create index(:toronto_neighborhoods, [:geog], using: :gist)

    flush()

    neighborhoods =
      :code.priv_dir(:bike_brigade)
      |> Path.join("repo/seeds/toronto_crs84.geojson")
      |> File.read!()
      |> Jason.decode!()

    entries =
      for neighborhood <- neighborhoods["features"] do
        %{
          neighborhood_id: String.to_integer(neighborhood["properties"]["AREA_S_CD"]),
          name: Regex.replace(~r/(.*) \(\d+\)/, neighborhood["properties"]["AREA_NAME"], "\\1"),
          geog: Geo.JSON.decode!(neighborhood["geometry"])
        }
      end

    BikeBrigade.Repo.insert_all("toronto_neighborhoods", entries)
  end

  def down do
    drop table(:toronto_neighborhoods)
  end
end
