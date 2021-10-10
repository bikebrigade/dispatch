defmodule BikeBrigade.Repo.Migrations.AddAssignToToTask do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      add :assigned_rider_id, references(:riders)
    end
  end
end
