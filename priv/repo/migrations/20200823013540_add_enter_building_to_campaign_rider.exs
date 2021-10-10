defmodule BikeBrigade.Repo.Migrations.AddEnterBuildingToCampaignRider do
  use Ecto.Migration

  def change do
    alter table(:campaigns_riders) do
      add :enter_building, :boolean
    end
  end
end
