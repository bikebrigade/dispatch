defmodule BikeBrigade.Repo.Migrations.AddPhotosToPrograms do
  use Ecto.Migration

  def change do
    alter table(:programs) do
      add(:photos, {:array, :string}, default: [])
    end
  end
end
