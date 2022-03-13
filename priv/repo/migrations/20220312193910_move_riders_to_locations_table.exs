defmodule BikeBrigade.Repo.Migrations.MoveRidersToLocationsTable do
  use Ecto.Migration
  import Ecto.Query

  def up do
    alter table(:riders) do
      add :location_id, references(:locations, on_delete: :delete_all)
    end

    flush()

    {rider_ids, locations} =
      BikeBrigade.Repo.all(
        from(r in "riders",
          select: {
            r.id,
            %{
              address: r.location["address"],
              city: r.location["city"],
              postal: r.location["postal"],
              province: r.location["province"],
              country: r.location["country"],
              unit: r.location["unit"],
              buzzer: r.location["buzzer"],
              coords: r.location["coords"]
            }
          }
        )
      )
      |> Enum.unzip()

    locations =
      for l <- locations do
        Map.merge(l, %{
          coords: Geo.JSON.decode!(l.coords),
          inserted_at: {:placeholder, :now},
          updated_at: {:placeholder, :now}
        })
      end

    {_, location_ids} =
      BikeBrigade.Repo.insert_all("locations", locations,
        placeholders: %{now: DateTime.utc_now()},
        returning: [:id]
      )

    rider_updates =
      Enum.zip_with([rider_ids, location_ids], fn [rider_id, %{id: location_id}] ->
        %{
          id: rider_id,
          location_id: location_id,
          inserted_at: {:placeholder, :now},
          updated_at: {:placeholder, :now}
        }
      end)

    BikeBrigade.Repo.insert_all(
      "riders",
      rider_updates,
      placeholders: %{now: DateTime.utc_now()},
      on_conflict: {:replace, [:location_id]},
      conflict_target: [:id]
    )
  end

  def down do
    alter table(:riders) do
      remove :location_id
    end
  end
end
