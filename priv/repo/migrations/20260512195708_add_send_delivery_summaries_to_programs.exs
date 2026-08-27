defmodule BikeBrigade.Repo.Migrations.AddSendDeliverySummariesToPrograms do
  use Ecto.Migration

  def change do
    alter table(:programs) do
      add :send_delivery_summaries, :boolean, default: false
    end
  end
end
