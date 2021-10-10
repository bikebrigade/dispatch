defmodule BikeBrigade.Repo.Migrations.AddSafetyCheckToRider do
  use Ecto.Migration

  def change do
    alter table(:riders) do
      add :last_safety_check, :date
    end
  end
end
