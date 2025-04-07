defmodule BikeBrigade.Repo.Migrations.CreateBannerTable do
  use Ecto.Migration

  def change do
    create table(:banners) do
      add :message, :text
      add :created_by, references :users
      add :turn_on_at, :date
      add :turn_off_at, :date
    end
  end
end
