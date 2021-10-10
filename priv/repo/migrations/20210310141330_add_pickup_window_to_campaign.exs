defmodule BikeBrigade.Repo.Migrations.AddPickupWindowToCampaign do
  use Ecto.Migration

  def change do
    alter table(:campaigns) do
      add :pickup_window, :text
    end
  end
end
