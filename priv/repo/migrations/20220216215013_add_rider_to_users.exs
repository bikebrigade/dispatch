defmodule BikeBrigade.Repo.Migrations.AddRiderToUsers do
  use Ecto.Migration

  import Ecto.Query

  alias BikeBrigade.Repo

  def up do
    alter table(:users) do
      add :rider_id, references(:riders), on_delete: :nothing
      add :is_dispatcher, :boolean, default: false
    end

    flush()

    # Making all the current users dispatchers
    from(u in "users",
      update: [set: [is_dispatcher: true]]
    )
    |> Repo.update_all([])

    # Assign rider_id to users if available
    from(u in "users",
      join: r in "riders",
      on: r.phone == u.phone,
      update: [set: [rider_id: r.id]]
    )
    |> Repo.update_all([])
  end

  def down do
    alter table(:users) do
      remove :rider_id
      remove :is_dispatcher
    end
  end
end
