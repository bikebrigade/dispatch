defmodule BikeBrigade.Repo.Migrations.AddResolvedFieldsToDeliveryNotes do
  use Ecto.Migration

  def change do
    alter table(:delivery_notes) do
      add :resolved, :boolean, default: false, null: false
      add :resolved_at, :utc_datetime
      add :resolved_by_id, references(:users, on_delete: :nothing)
    end

    create index(:delivery_notes, [:resolved])
    create index(:delivery_notes, [:resolved_by_id])
  end
end
