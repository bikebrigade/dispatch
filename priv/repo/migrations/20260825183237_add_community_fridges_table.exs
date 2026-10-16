defmodule BikeBrigade.Repo.Migrations.AddCommunityFridgesTable do
  use Ecto.Migration

  def change do
    create table(:community_fridges) do
      add :name, :string, null: false
      add :description, :text
      add :photo, :string
      add :active, :boolean, default: true, null: false
      add :pair_preferred, :boolean, default: false, null: false
      add :location_id, references(:locations, on_delete: :nilify_all)

      timestamps()
    end

    create unique_index(:community_fridges, [:location_id])
  end
end
