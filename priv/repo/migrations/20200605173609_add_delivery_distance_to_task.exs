defmodule BikeBrigade.Repo.Migrations.AddDeliveryDistanceToTask do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      add :delivery_distance,
          :"integer GENERATED ALWAYS AS (st_distance(pickup_location, dropoff_location)) STORED"
    end
  end
end
