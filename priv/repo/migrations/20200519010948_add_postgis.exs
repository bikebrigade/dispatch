defmodule BikeBrigade.Repo.Migrations.AddPostgis do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION postgis"
  end
  def down do
    execute "DROP EXTENSION postgis"
  end
end
