defmodule BikeBrigade.Repo.Migrations.AddDropoffPhoneToTask do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      add :dropoff_phone, :string
    end
  end
end
