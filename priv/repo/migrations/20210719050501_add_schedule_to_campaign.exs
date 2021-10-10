defmodule BikeBrigade.Repo.Migrations.AddScheduleToCampaign do
  use Ecto.Migration

  def change do
    create table(:scheduled_messages) do
      add :campaign_id, references(:campaigns)
      add :send_at, :utc_datetime
      timestamps()
    end

    create unique_index(:scheduled_messages, [:campaign_id])
    create index(:scheduled_messages, [:send_at])
  end
end
