defmodule BikeBrigade.Repo.Migrations.AddUnifiedMessaging do
  use Ecto.Migration

  def change do
    create table(:bulk_message_groups) do
      add :name, :text, null: false
      add :body, :text, null: false
      add :creator_id, references(:users), null: false

      timestamps()
    end

    create index(:bulk_message_groups, [:inserted_at])

    create table(:bulk_message_group_riders, primary_key: false) do
      add :group_id, references(:bulk_message_groups, on_delete: :delete_all), null: false
      add :rider_id, references(:riders, on_delete: :delete_all), null: false
    end

    create unique_index(:bulk_message_group_riders, [:group_id, :rider_id])
    create index(:bulk_message_group_riders, [:rider_id])
  end
end
