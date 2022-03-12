defmodule BikeBrigade.Repo.Migrations.LocationsTable do
  use Ecto.Migration

  def change do
    create table(:locations) do
      add :address, :string
      add :city, :string
      add :postal, :string
      add :province, :string
      add :country, :string
      add :unit, :string
      add :buzzer, :string

      add :coords, :geography

      timestamps()
    end
  end
end
