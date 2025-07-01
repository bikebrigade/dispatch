defmodule BikeBrigade.Repo.Migrations.AddBannerTable do
  use Ecto.Migration

  def change do
    create table(:banners) do
      add :message, :text
      add :created_by, references(:users)
      add :turn_on_at, :date
      add :turn_off_at, :date
      add :enabled, :boolean
    end
  end
end
