defmodule BikeBrigade.Repo.Migrations.CreateBannerTable do
  use Ecto.Migration

  def change do
    create table(:banners) do
      add :message, :text
      add :created_by_user_id, references :users
      add :turn_on_at, :utc_datetime
      add :turn_off_at, :utc_datetime
    end
  end
end
