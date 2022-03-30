defmodule BikeBrigade.Repo.Migrations.TaskLocation do
  use Ecto.Migration
  import BikeBrigade.MigrationUtils

  import Ecto.Query
  import Geo.PostGIS

  def up do
    # need to drop this view becaus it depends on delivery distance column
    # no way to change a generated column, we have to drop and re create it
    execute "drop view if exists rider_stats"
    execute "drop view if exists campaign_stats"

    rename table(:tasks), :dropoff_location, to: :dropoff_coords
    rename table(:tasks), :pickup_location, to: :pickup_coords

    alter table(:tasks) do
      add :dropoff_location, :map
      add :pickup_location, :map
      remove_if_exists(:delivery_distance, :integer)
    end

    flush()

    query =
      from(t in "tasks",
        join: pn in "toronto_neighborhoods",
        on: st_covers(pn.geog, t.pickup_coords),
        join: dn in "toronto_neighborhoods",
        on: st_covers(dn.geog, t.dropoff_coords),
        update: [
          set: [
            pickup_location:
              fragment(
                "jsonb_build_object('coords', ST_AsGeoJSON(?)::jsonb, 'address', ?, 'city', ?, 'postal', ?, 'province', ?, 'country', 'Canada', 'neighborhood', ?)",
                t.pickup_coords,
                t.pickup_address,
                t.pickup_city,
                t.pickup_postal,
                t.pickup_province,
                pn.name
              ),
            dropoff_location:
              fragment(
                "jsonb_build_object('coords', ST_AsGeoJSON(?)::jsonb, 'address', ?, 'city', ?, 'postal', ?, 'province', ?, 'country', 'Canada', 'neighborhood', ?)",
                t.dropoff_coords,
                t.dropoff_address,
                t.dropoff_city,
                t.dropoff_postal,
                t.dropoff_province,
                dn.name
              )
          ]
        ]
      )

    BikeBrigade.Repo.update_all(query, [])

    flush()

    alter table(:tasks) do
      add :delivery_distance,
          :"integer GENERATED ALWAYS AS (st_distance(ST_GeomFromGeoJSON(pickup_location ->> 'coords') , ST_GeomFromGeoJSON(dropoff_location ->> 'coords'))) STORED"
    end

    # removing since we load these views later
    # load_sql("rider_stats_view.sql")
    # load_sql("campaign_stats_view.sql")
  end

  def down do
    execute "drop view if exists rider_stats"

    alter table(:tasks) do
      remove_if_exists(:dropoff_location, :map)
      remove_if_exists(:pickup_location, :map)
      remove_if_exists(:delivery_distance, :integer)
    end

    rename table(:tasks), :dropoff_coords, to: :dropoff_location
    rename table(:tasks), :pickup_coords, to: :pickup_location

    flush()

    alter table(:tasks) do
      add :delivery_distance,
          :"integer GENERATED ALWAYS AS (st_distance(pickup_location, dropoff_location)) STORED"
    end

    # removing since we load these views later
    # load_sql("rider_stats_view.sql")
    # load_sql("campaign_stats_view.sql")
  end
end
