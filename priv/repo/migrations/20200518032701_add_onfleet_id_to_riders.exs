defmodule BikeBrigade.Repo.Migrations.AddOnfleetIdToRiders do
  use Ecto.Migration

  def change do
    alter table(:riders) do
      add :onfleet_id, :string
      add :onfleet_account_status, :string
      add :deliveries_completed, :integer, default: 0
    end

    create unique_index(:riders, [:onfleet_id])
  end
end
