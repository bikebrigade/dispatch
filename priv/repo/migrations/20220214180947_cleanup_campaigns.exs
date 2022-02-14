defmodule BikeBrigade.Repo.Migrations.CleanupCampaigns do
  use Ecto.Migration

  def change do
    alter table(:campaigns) do
      remove :delivery_date
      remove :pickup_address
      remove :pickup_address2
      remove :pickup_city
      remove :pickup_country
      remove :pickup_location
      remove :pickup_postal
      remove :pickup_province
      remove :name
    end
  end
end
