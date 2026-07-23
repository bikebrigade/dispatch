defmodule BikeBrigade.Repo.Migrations.AddNotNullConstraintToSendDeliverySummaries do
  use Ecto.Migration

  def up do
    alter table(:programs) do
      modify :send_delivery_summaries, :boolean, null: false
    end
  end

  def down do
    alter table(:programs) do
      modify :send_delivery_summaries, :boolean, null: true
    end
  end
end
