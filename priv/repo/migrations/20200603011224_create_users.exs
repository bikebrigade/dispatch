defmodule BikeBrigade.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :email, :string
      add :phone, :string

      timestamps()
    end

    create unique_index(:users, [:phone])
    create unique_index(:users, [:email])
  end
end
