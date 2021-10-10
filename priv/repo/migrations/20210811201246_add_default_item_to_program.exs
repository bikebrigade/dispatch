defmodule BikeBrigade.Repo.Migrations.AddDefaultItemToProgram do
  use Ecto.Migration

  def change do
    alter table(:programs) do
      add :default_item_id, references(:items)
    end
  end
end
