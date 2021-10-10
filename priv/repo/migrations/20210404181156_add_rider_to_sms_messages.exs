defmodule BikeBrigade.Repo.Migrations.AddRiderToSmsMessages do
  use Ecto.Migration

  def change do
    alter table(:sms_messages) do
      add :incoming, :boolean, default: false
      add :rider_id, references(:riders)
    end
    drop index(:sms_messages, [:sent_at])
    create index(:sms_messages, [:rider_id, :sent_at])
  end
end
