defmodule BikeBrigade.Repo.Migrations.AddUniqueIndexToTaskItems do
  use Ecto.Migration

  def change do
    create unique_index(:tasks_items, [:task_id, :item_id])
  end
end
