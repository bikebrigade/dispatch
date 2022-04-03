defmodule BikeBrigade.Repo.Migrations.MigrateTaskLocations do
  import BikeBrigade.MigrationUtils

  use Ecto.Migration

  import Ecto.Query

  @table_name "tasks"

  def up do
    # removing since we load these views later
    # execute "drop view if exists rider_stats"
    # execute "drop view if exists campaign_stats"

    alter table(@table_name) do
      add :pickup_location_id, references(:locations)
      add :dropoff_location_id, references(:locations)
      remove_if_exists(:delivery_distance, :integer)
    end

    # removing since we load these views later
    # load_sql("campaign_stats_view.sql", "drop view if exists campaign_stats")
    # load_sql("rider_stats_view.sql", "drop view if exists rider_stats")

    flush()

    {ids, pickup_locations, dropoff_locations} =
      BikeBrigade.Repo.all(
        from(r in @table_name,
          select: {
            r.id,
            %{
              address: r.pickup_location["address"],
              city: r.pickup_location["city"],
              postal: r.pickup_location["postal"],
              province: r.pickup_location["province"],
              country: r.pickup_location["country"],
              unit: r.pickup_location["unit"],
              buzzer: r.pickup_location["buzzer"],
              coords: r.pickup_location["coords"]
            },
            %{
              address: r.dropoff_location["address"],
              city: r.dropoff_location["city"],
              postal: r.dropoff_location["postal"],
              province: r.dropoff_location["province"],
              country: r.dropoff_location["country"],
              unit: r.dropoff_location["unit"],
              buzzer: r.dropoff_location["buzzer"],
              coords: r.dropoff_location["coords"]
            }
          }
        )
      )
      |> unzip()

    pickup_locations =
      for l <- pickup_locations do
        Map.merge(l, %{
          coords: Geo.JSON.decode!(l.coords),
          inserted_at: {:placeholder, :now},
          updated_at: {:placeholder, :now}
        })
      end

    dropoff_locations =
      for l <- dropoff_locations do
        Map.merge(l, %{
          coords: Geo.JSON.decode!(l.coords),
          inserted_at: {:placeholder, :now},
          updated_at: {:placeholder, :now}
        })
      end

    {_, pickup_location_ids} =
      chunked_insert_all("locations", pickup_locations,
        placeholders: %{now: DateTime.utc_now()},
        returning: [:id]
      )

    {_, dropoff_location_ids} =
      chunked_insert_all("locations", dropoff_locations,
        placeholders: %{now: DateTime.utc_now()},
        returning: [:id]
      )

    updates =
      Enum.zip_with(
        [ids, pickup_location_ids, dropoff_location_ids],
        fn [ids, %{id: pickup_location_id}, %{id: dropoff_location_id}] ->
          %{
            id: ids,
            pickup_location_id: pickup_location_id,
            dropoff_location_id: dropoff_location_id,
            inserted_at: {:placeholder, :now},
            updated_at: {:placeholder, :now}
          }
        end
      )

    chunked_insert_all(
      @table_name,
      updates,
      placeholders: %{now: DateTime.utc_now()},
      on_conflict: {:replace, [:pickup_location_id, :dropoff_location_id]},
      conflict_target: [:id]
    )
  end

  def down do
    # removing since we load these views later
    # execute "drop view if exists rider_stats"
    # execute "drop view if exists campaign_stats"
    flush()

    alter table(@table_name) do
      remove :pickup_location_id
      remove :dropoff_location_id

      add :delivery_distance,
          :"integer GENERATED ALWAYS AS (st_distance(ST_GeomFromGeoJSON(pickup_location ->> 'coords') , ST_GeomFromGeoJSON(dropoff_location ->> 'coords'))) STORED"
    end
  end

  # need out own unzip since Enum.unzip does two tuples
  def unzip(list) do
    {l1, l2, l3} =
      Enum.reduce(list, {[], [], []}, fn {el1, el2, el3}, {l1, l2, l3} ->
        {[el1 | l1], [el2 | l2], [el3 | l3]}
      end)

    {Enum.reverse(l1), Enum.reverse(l2), Enum.reverse(l3)}
  end

  @chunk_every 1000
  defp chunked_insert_all(table, entries, opts) do
    Enum.chunk_every(entries, @chunk_every)
    |> Enum.map(&BikeBrigade.Repo.insert_all(table, &1, opts))
    |> Enum.reduce({0,[]}, fn {count, results}, {total, all_results} ->
      {total + count, all_results ++ results}
    end)
  end
end
