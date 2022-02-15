defmodule BikeBrigade.Repo.Migrations.CleanupTasks do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      remove :delivery_date
    end
  end
end
