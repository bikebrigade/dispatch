defmodule BikeBrigade.Repo.Migrations.ModifyOnDeleteForTasksItems do
  use Ecto.Migration

  def change do
    alter table(:tasks_items) do
      modify :item_id, references(:items, on_delete: :restrict),
        from: references(:items, on_delete: :delete_all)
    end
  end
end
