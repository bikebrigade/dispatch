defmodule BikeBrigade.Repo.Migrations.CreateSmsMessages do
  use Ecto.Migration

  def change do
    create table(:sms_messages) do
      add :to, :string
      add :from, :string
      add :body, :text
      add :sent_at, :utc_datetime
      add :twilio_sid, :string

      timestamps()
    end
  end
end
