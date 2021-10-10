defmodule BikeBrigade.Repo.Migrations.AddTokenToCampaignRider do
  use Ecto.Migration

  def change do
    alter table(:campaigns_riders) do
      add :token, :string
    end

    create(unique_index(:campaigns_riders, [:token]))
  end
end
