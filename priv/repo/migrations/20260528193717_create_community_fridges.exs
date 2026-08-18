defmodule BikeBrigade.Repo.Migrations.CreateCommunityFridges do
  use Ecto.Migration

  def change do
    create table(:community_fridges) do
      add :name, :string
      add :description, :text
      add :photo, :string
      add :active, :boolean, default: true, null: false
      add :pair_preferred, :boolean, default: false, null: false
      add :location_id, references(:locations, on_delete: :nilify_all)

      timestamps()
    end
  end
end
