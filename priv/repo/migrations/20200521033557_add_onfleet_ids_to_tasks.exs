defmodule BikeBrigade.Repo.Migrations.AddOnfleetIdsToTasks do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      add :onfleet_pickup_id, :string
      add :onfleet_dropoff_id, :string
    end
  end
end
