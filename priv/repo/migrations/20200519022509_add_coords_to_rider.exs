defmodule BikeBrigade.Repo.Migrations.AddCoordsToRider do
  use Ecto.Migration

  def change do
    alter table(:riders) do
      add :location, :geography
    end
  end
end
