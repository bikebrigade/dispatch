defmodule BikeBrigade.Repo.Migrations.AddRestrictedToTags do
  use Ecto.Migration

  def change do
    alter table(:tags) do
      add :restricted, :boolean, default: false, null: false
    end
  end
end
