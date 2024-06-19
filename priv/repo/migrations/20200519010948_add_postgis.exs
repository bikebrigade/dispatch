defmodule BikeBrigade.Repo.Migrations.AddPostgis do
  use Ecto.Migration

  def up do
    execute "set pgaudit.log='none'"
    execute "CREATE EXTENSION postgis"
    execute "set pgaudit.log='ddl'"
  end

  def down do
    execute "DROP EXTENSION postgis"
  end
end
