defmodule BikeBrigade.Repo.Migrations.AddHiddenToItems do
  use Ecto.Migration

  def change do
    alter table(:items) do
      add :hidden, :boolean, default: false
    end
  end
end
