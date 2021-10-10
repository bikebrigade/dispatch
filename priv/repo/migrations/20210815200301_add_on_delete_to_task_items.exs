defmodule BikeBrigade.Repo.Migrations.AddOnDeleteToTaskItems do
  use Ecto.Migration

  def change do
    alter table(:tasks_items) do
      modify :task_id, references(:tasks, on_delete: :delete_all), from: references(:tasks)
      modify :item_id, references(:items, on_delete: :delete_all), from: references(:items)
    end
  end
end
