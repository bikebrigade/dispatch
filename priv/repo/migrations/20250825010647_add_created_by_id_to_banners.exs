defmodule BikeBrigade.Repo.Migrations.AddCreatedByIdToBanners do
  use Ecto.Migration

  def change do
    alter table(:banners) do
      add_if_not_exists :created_by_id, references(:users), null: true
    end
  end
end
