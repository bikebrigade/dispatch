defmodule BikeBrigade.Repo.Migrations.AddPickupLocationToCampaign do
  use Ecto.Migration

  def change do
    alter table(:campaigns) do
      add :pickup_address, :string
      add :pickup_address2, :string
      add :pickup_city, :string
      add :pickup_province, :string
      add :pickup_postal, :string
      add :pickup_country, :string
      add :pickup_location, :geography
    end
  end
end
