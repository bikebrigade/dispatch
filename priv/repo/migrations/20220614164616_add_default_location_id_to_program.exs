defmodule BikeBrigade.Repo.Migrations.AddDefaultLocationIdToProgram do
  use Ecto.Migration
  import Ecto.Query
  alias BikeBrigade.Delivery.Campaign
  alias BikeBrigade.Locations.Location
  alias BikeBrigade.Repo

  @table_name "programs"

  def up do
    alter table(@table_name) do
      add :default_location_id, references(:locations)
    end

    flush()

    now = DateTime.utc_now()

    {program_ids, locations} =
      from(
        p in "programs",
        inner_join: pc in "programs_latest_campaigns",
        on: pc.program_id == p.id,
        inner_join: c in Campaign,
        on: pc.campaign_id == c.id,
        inner_join: l in assoc(c, :location),
        select:
          {p.id,
           %{
             address: l.address,
             city: l.city,
             postal: l.postal,
             province: l.province,
             country: l.country,
             unit: l.unit,
             buzzer: l.buzzer,
             coords: l.coords
           }}
      )
      |> Repo.all()
      |> Enum.unzip()

    locations =
      Enum.map(locations, fn l ->
        Map.merge(l, %{inserted_at: {:placeholder, :now}, updated_at: {:placeholder, :now}})
      end)

    {_count, locations} =
      Repo.insert_all(Location, locations,
        placeholders: %{now: DateTime.utc_now()},
        returning: [:id]
      )

    for {program_id, location} <- Enum.zip(program_ids, locations) do
      q = from(p in @table_name, where: p.id == ^program_id)
      Repo.update_all(q, set: [default_location_id: location.id])
    end
  end

  def down do
    alter table(@table_name) do
      remove :default_location_id
    end
  end
end
