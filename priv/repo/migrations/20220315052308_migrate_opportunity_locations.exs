defmodule BikeBrigade.Repo.Migrations.MigrateOpportunityLocations do
  use Ecto.Migration

  import Ecto.Query

  @table_name "delivery_opportunities"

  def up do
    alter table(@table_name) do
      add :location_id, references(:locations)
    end

    flush()

    {ids, locations} =
      BikeBrigade.Repo.all(
        from(r in @table_name,
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

    updates =
      Enum.zip_with([ids, location_ids], fn [ids, %{id: location_id}] ->
        %{
          id: ids,
          location_id: location_id,
          inserted_at: {:placeholder, :now},
          updated_at: {:placeholder, :now}
        }
      end)

    BikeBrigade.Repo.insert_all(
      @table_name,
      updates,
      placeholders: %{now: DateTime.utc_now()},
      on_conflict: {:replace, [:location_id]},
      conflict_target: [:id]
    )
  end

  def down do
    alter table(@table_name) do
      remove :location_id
    end
  end
end
