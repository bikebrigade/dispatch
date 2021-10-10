defmodule BikeBrigade.Repo.Migrations.RemoveNameIndexFromCampaigns do
  use Ecto.Migration

  def change do
    drop unique_index(:task_collections, [:name])
  end
end
