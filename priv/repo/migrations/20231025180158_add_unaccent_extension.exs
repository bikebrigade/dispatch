defmodule BikeBrigade.Repo.Migrations.AddUnaccentExtension do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS unaccent;"
  end

  def down do
    execute "DROP EXTENSION IF EXISTS unaccent;"
  end
end
