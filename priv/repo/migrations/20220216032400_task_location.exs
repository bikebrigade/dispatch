defmodule BikeBrigade.Repo.Migrations.TaskLocation do
  use Ecto.Migration

  import Ecto.Query
  import Geo.PostGIS

  def up do
    rename table(:tasks), :dropoff_location, to: :dropoff_coords
    rename table(:tasks), :pickup_location, to: :pickup_coords

    alter table(:tasks) do
      add :dropoff_location, :map
      add :pickup_location, :map
    end

    flush()

    query =
      from(t in "tasks",
        join: n in "toronto_neighborhoods",
        on: st_covers(n.geog, t.dropoff_coords),
        update: [
          set: [
            dropoff_location:
              fragment(
                "jsonb_build_object('coords', ST_AsGeoJSON(?)::jsonb, 'address', ?, 'city', ?, 'postal', ?, 'province', ?, 'country', 'Canada', 'neighborhood', ?)",
                t.dropoff_coords,
                t.dropoff_address,
                t.dropoff_city,
                t.dropoff_postal,
                t.dropoff_province,
                n.name
              )
          ]
        ]
      )

    BikeBrigade.Repo.update_all(query, [])
  end

  def down do
    alter table(:tasks) do
      remove :dropoff_location, :map
      remove :pickup_location, :map
    end

    flush()
    rename table(:tasks), :dropoff_coords, to: :dropoff_location
    rename table(:tasks), :pickup_coords, to: :pickup_location
  end
end
