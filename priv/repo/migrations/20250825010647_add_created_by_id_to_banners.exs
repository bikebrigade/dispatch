defmodule BikeBrigade.Repo.Migrations.AddCreatedByIdToBanners do
  use Ecto.Migration

  def change do
    drop_if_exists table(:banners)

    create table(:banners) do
      add :message, :text
      add :created_by_id, references(:users)
      add :turn_on_at, :utc_datetime
      add :turn_off_at, :utc_datetime
      add :enabled, :boolean
    end
  end
end
