defmodule BikeBrigade.Repo.Migrations.AddIndexToRiders do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION pg_trgm", "DROP EXTENSION pg_trgm"
    create index(:riders, [:name])

    execute "CREATE INDEX  index_riders_on_name_trigram
    ON riders
    USING gin (name gin_trgm_ops)",
            "DROP INDEX  index_riders_on_name_trigram"

    create index(:campaigns, [:delivery_start])
  end
end
