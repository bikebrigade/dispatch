defmodule BikeBrigade.Repo.Migrations.RemoveResolvedFromDeliveryNotes do
  use Ecto.Migration

  def change do
    alter table(:delivery_notes) do
      remove :resolved
    end
  end
end
