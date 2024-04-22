defmodule BikeBrigade.Repo.Migrations.AddPublicToProgram do
  use Ecto.Migration

  def change do
    alter table(:programs) do
      add(:public, :boolean, default: false)
    end
  end
end
