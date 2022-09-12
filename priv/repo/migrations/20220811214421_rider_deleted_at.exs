defmodule BikeBrigade.Repo.Migrations.RiderDeletedAt do
  use Ecto.Migration
  import BikeBrigade.MigrationUtils


  def change do
    alter table(:riders) do
      add :deleted_at, :utc_datetime, default: nil
    end
  end
end
