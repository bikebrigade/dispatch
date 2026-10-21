defmodule BikeBrigade.Repo.Migrations.RemoveLocationIdFromCommunityFridges do
  use Ecto.Migration

  def change do
    drop_if_exists unique_index(:community_fridges, [:location_id])
  end
end
