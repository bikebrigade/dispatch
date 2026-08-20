defmodule BikeBrigade.Repo.Migrations.AddCommunityFridgeToPrograms do
  use Ecto.Migration

  def change do
    alter table(:programs) do
      add :community_fridge, :boolean, default: false
    end
  end
end
