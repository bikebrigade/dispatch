defmodule BikeBrigade.Repo.Migrations.AddBackupRiderToCampaignRiders do
  use Ecto.Migration

  def change do
    alter table(:campaigns_riders) do
      add :backup_rider, :boolean, default: false, null: false
    end
  end
end
