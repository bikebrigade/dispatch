defmodule BikeBrigade.Repo.Migrations.CreateRiders do
  use Ecto.Migration

  def change do
    create table(:riders) do
      add :name, :string
      add :email, :string
      add :address, :string
      add :address2, :string
      add :city, :string
      add :province, :string
      add :postal, :string
      add :country, :string
      add :phone, :string
      add :pronouns, :string
      add :availability, :map
      add :capacity, :integer
      add :max_distance, :integer
      add :signed_up_on, :naive_datetime

      timestamps()
    end

    create unique_index(:riders, [:phone])
    create unique_index(:riders, [:email])
  end
end
