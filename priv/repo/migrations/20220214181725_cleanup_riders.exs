defmodule BikeBrigade.Repo.Migrations.CleanupRiders do
  use Ecto.Migration

  def change do
    alter table(:riders) do
      remove :address
      remove :address2
      remove :city
      remove :country
      remove :postal
      remove :province
      remove :onfleet_id
      remove :onfleet_account_status
      remove :location
    end

    rename table(:riders), :location_struct, to: :location
  end
end
