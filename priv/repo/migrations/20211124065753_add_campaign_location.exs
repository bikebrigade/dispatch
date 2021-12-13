defmodule BikeBrigade.Repo.Migrations.AddCampaignLocation do
  use Ecto.Migration

  def change do
    alter table(:campaigns) do
      add :location, :map
    end
  end
end
