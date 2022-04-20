defmodule BikeBrigade.Repo.Migrations.SmsMessageCampaignReference do
  use Ecto.Migration

  def change do
    alter table(:sms_messages) do
      modify(:campaign_id, references(:campaigns, on_delete: :nilify_all),
        from: references(:campaigns)
      )
    end
  end
end
