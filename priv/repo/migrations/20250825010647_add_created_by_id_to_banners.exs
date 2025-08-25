defmodule BikeBrigade.Repo.Migrations.AddCreatedByIdToBanners do
  use Ecto.Migration

  def change do
    alter table(:banners) do
      add :created_by_id, references(:users), null: true
    end

    create index(:banners, [:created_by_id])
  end
end
