defmodule BikeBrigade.Repo.Migrations.AddMissingIndexes do
  use Ecto.Migration

  def change do
    create index :tasks, [:campaign_id]
    create index :tasks, [:assigned_rider_id]
  end
end
