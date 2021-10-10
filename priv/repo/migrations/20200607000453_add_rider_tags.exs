defmodule BikeBrigade.Repo.Migrations.AddRiderTags do
  use Ecto.Migration

  def change do
    execute("CREATE EXTENSION citext", "DROP EXTENSION citext")

    create table(:tags) do
      add(:name, :citext)

      timestamps()
    end

    create table(:riders_tags) do
      add(:tag_id, references(:tags))
      add(:rider_id, references(:riders))

      timestamps()
    end

    create(unique_index(:tags, [:name]))
    create(unique_index(:riders_tags, [:tag_id, :rider_id]))
  end
end
