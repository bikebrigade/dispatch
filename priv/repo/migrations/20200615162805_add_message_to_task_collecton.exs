defmodule BikeBrigade.Repo.Migrations.AddMessageToTaskCollecton do
  use Ecto.Migration

  def change do
    alter table(:task_collections) do
      add :message, :text
      add :message_sent_at, :utc_datetime
    end
  end
end
