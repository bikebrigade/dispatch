defmodule BikeBrigade.Repo.Migrations.RenameTaskCollection do
  use Ecto.Migration

  def change do
    rename table(:task_collections), to: table(:campaigns)
    rename table(:task_collections_tasks), to: table(:campaigns_tasks)
  end
end
