defmodule BikeBrigade.Repo.Migrations.AddLocationToOpportunity do
  use Ecto.Migration

  import Ecto.Query

  def up do
    alter table(:delivery_opportunities) do
      add :location, :map
    end

    flush()

    from(o in "delivery_opportunities",
      join: p in "programs",
      on: o.program_id == p.id,
      join: l in "programs_latest_campaigns",
      on: l.program_id == p.id,
      join: c in "campaigns",
      on: l.campaign_id == c.id,
      update: [set: [location: c.location]]
    )
    |> BikeBrigade.Repo.update_all([])
  end

  def down do
    alter table(:delivery_opportunities) do
      remove :location
    end
  end
end
