defmodule BikeBrigade.Repo.Migrations.TaskCollectionsUniqueName do
  use Ecto.Migration

  def change do
    create unique_index(:task_collections, [:name])

  end
end
