defmodule BikeBrigade.Repo.Migrations.CreateImporter do
  use Ecto.Migration

  def change do
    create table(:importers) do
      add :name, :string
      add :data, :map

      timestamps()
    end

    create unique_index(:importers, [:name])
  end
end
