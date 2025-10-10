defmodule BikeBrigade.Repo.Migrations.AddDeliveryNotesTable do
  use Ecto.Migration

  def change do
    create table(:delivery_notes) do
      add :note, :text, null: false
      add :rider_id, references(:riders, on_delete: :nothing), null: false
      add :task_id, references(:tasks, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:delivery_notes, [:rider_id])
    create index(:delivery_notes, [:task_id])
  end
end
