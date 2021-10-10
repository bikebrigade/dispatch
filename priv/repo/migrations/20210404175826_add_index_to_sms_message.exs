defmodule BikeBrigade.Repo.Migrations.AddIndexToSmsMessage do
  use Ecto.Migration

  def change do
    create index(:sms_messages, [:from])
    create index(:sms_messages, [:to])
    create index(:sms_messages, [:sent_at])
  end
end
