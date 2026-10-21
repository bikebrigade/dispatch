defmodule BikeBrigade.Repo.Migrations.AddFlagsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :flags, :map, null: false, default: %{}
    end
  end
end
