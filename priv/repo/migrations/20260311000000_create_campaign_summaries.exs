defmodule BikeBrigade.Repo.Migrations.CreateCampaignSummaries do
  use Ecto.Migration

  def change do
    create table(:campaign_summaries) do
      add :campaign_id, references(:campaigns, on_delete: :delete_all), null: false
      add :send_at, :utc_datetime
      timestamps()
    end

    create unique_index(:campaign_summaries, [:campaign_id])
  end
end
