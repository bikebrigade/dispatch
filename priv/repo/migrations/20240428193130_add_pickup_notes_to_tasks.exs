defmodule BikeBrigade.Repo.Migrations.AddPickupNotesToTasks do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      add :pickup_notes, :text
    end
  end
end
