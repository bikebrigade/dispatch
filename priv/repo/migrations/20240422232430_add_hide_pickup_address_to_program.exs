defmodule BikeBrigade.Repo.Migrations.AddHidePickupAddressToProgram do
  use Ecto.Migration

  def change do
    alter table(:programs) do
      add(:hide_pickup_address, :boolean, default: false)
    end
  end
end
