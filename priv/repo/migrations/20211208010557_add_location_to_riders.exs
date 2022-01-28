defmodule BikeBrigade.Repo.Migrations.AddLocationToRiders do
  use Ecto.Migration

  def change do
    alter table(:riders) do
      add :location_struct, :map
    end
  end
end
