defmodule BikeBrigade.Repo.Migrations.ConstraintsTaskCollections do
  use Ecto.Migration
  def change do
    alter table(:task_collections_tasks) do

      modify :task_collection_id, references(:task_collections, on_delete: :delete_all),
        from: references(:task_collections)
      modify :task_id, references(:tasks, on_delete: :delete_all),
        from: references(:tasks)
    end
  end
end
