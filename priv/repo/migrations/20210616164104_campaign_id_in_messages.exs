defmodule BikeBrigade.Repo.Migrations.CampaignIdInMessages do
  use Ecto.Migration

  def up do

    alter table(:sms_messages) do
      remove :template_id
      add :campaign_id, references(:campaigns)
    end

    create index :sms_messages, [:campaign_id]

  end

  def down do

    alter table(:sms_messages) do
      remove :campaign_id
      add :template_id, references(:message_templates)
    end
  end
end
