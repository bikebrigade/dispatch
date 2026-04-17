defmodule BikeBrigade.Repo.Migrations.AddSlackCampaignSummaries do
  use Ecto.Migration

  def change do
    create table(:slack_campaign_summaries) do
      add :slack_channel_id, :string, null: false
      add :raw_message, :text, null: false
      add :sent_at, :utc_datetime
      add :campaign_id, references(:campaigns, on_delete: :nilify_all)

      timestamps()
    end

    create unique_index(:slack_campaign_summaries, [:campaign_id])
    create index(:slack_campaign_summaries, [:sent_at])
  end
end
