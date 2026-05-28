defmodule BikeBrigade.Repo.Migrations.AddCommunityFridgeToTasks do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      add :community_fridge_id, references(:community_fridges), null: true
    end
  end
end
