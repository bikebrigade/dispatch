defmodule BikeBrigade.Repo.Migrations.CreateItems do
  use Ecto.Migration

  def change do
    create table(:items) do
      add :name, :string
      add :plural_name, :string
      add :description, :text
      add :category, :string
      add :photo, :string

      timestamps()
    end

    create table(:tasks_items) do
      add :task_id, references(:tasks)
      add :item_id, references(:items)
      add :count, :integer

      timestamps()
    end
  end
end
