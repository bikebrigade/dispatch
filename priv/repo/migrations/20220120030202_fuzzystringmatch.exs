defmodule BikeBrigade.Repo.Migrations.Fuzzystringmatch do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION fuzzystrmatch", "DROP EXTENSION fuzzystrmatch"
  end
end
