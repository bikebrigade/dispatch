defmodule BikeBrigade.Repo.Migrations.AddStatusToSmsMessages do
  use Ecto.Migration

  def change do
    alter table(:sms_messages) do
      add :twilio_status, :string
    end

    create index(:sms_messages, [:twilio_sid])
  end
end
