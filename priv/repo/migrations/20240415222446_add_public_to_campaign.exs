defmodule BikeBrigade.Repo.Migrations.AddPublicToCampaign do
  use Ecto.Migration

  def change do
    alter table(:campaigns) do
      add :public, :boolean, default: false
    end
  end
end
