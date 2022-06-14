defmodule BikeBrigade.Repo.Migrations.AddDefaultLocationIdToProgram do
  use Ecto.Migration

  import Ecto.Query

  @table_name "programs"

  def change do
    alter table(@table_nam) do
      add :default_location_id, references(:locations)
    end
  end
end
