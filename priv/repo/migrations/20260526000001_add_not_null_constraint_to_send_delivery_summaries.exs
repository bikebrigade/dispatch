defmodule BikeBrigade.Repo.Migrations.AddNotNullConstraintToSendDeliverySummaries do
  use Ecto.Migration

  def change do
    alter table(:programs) do
      modify :send_delivery_summaries, :boolean, null: false
    end
  end
end
