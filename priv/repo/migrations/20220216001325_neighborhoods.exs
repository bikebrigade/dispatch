defmodule BikeBrigade.Repo.Migrations.Neighborhoods do
  use Ecto.Migration

  def up do
    create table(:toronto_neighborhoods) do
      add :neighborhood_id, :integer
      add :name, :string
      add :geog, :geography
    end

    create index(:toronto_neighborhoods, [:geog], using: :gist)

    # Data seeding removed — see migration 20260319000001_reload_neighborhoods.exs
  end

  def down do
    drop table(:toronto_neighborhoods)
  end
end
