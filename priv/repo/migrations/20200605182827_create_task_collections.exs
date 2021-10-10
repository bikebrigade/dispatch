defmodule BikeBrigade.Repo.Migrations.CreateTaskCollections do
  use Ecto.Migration

  def change do
    create table(:task_collections) do
      add :name, :string

      timestamps()
    end

    create table(:task_collections_tasks) do
      add :task_collection_id, references(:task_collections)
      add :task_id, references(:tasks)

      timestamps()
    end

    create unique_index(:task_collections_tasks, [:task_collection_id, :task_id])
  end
end
