defmodule BikeBrigade.Repo.Migrations.AddTextBasedItineraryToRidersTable do
  use Ecto.Migration

  def change do
    alter table(:riders) do
      add :text_based_itinerary, :boolean, default: false, null: false
    end
  end
end
