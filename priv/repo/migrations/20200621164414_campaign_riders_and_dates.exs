defmodule BikeBrigade.Repo.Migrations.CampaignRidersAndDates do
  use Ecto.Migration

  def change do
    create table(:campaigns_riders) do
      add :campaign_id, references(:campaigns)
      add :rider_id, references(:riders)
      add :rider_capacity, :integer
      timestamps()
    end

    create(unique_index(:campaigns_riders, [:campaign_id, :rider_id]))

    alter table(:campaigns) do
      add :delivery_start, :utc_datetime
      add :delivery_end, :utc_datetime
      add :welcome_template, references(:message_templates)
    end
  end
end
