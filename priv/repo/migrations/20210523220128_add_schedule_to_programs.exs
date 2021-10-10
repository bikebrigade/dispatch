defmodule BikeBrigade.Repo.Migrations.AddScheduleToPrograms do
  use Ecto.Migration

  def change do
    alter table(:programs) do
      add :start_date, :date
      add :schedules, {:array, :map}
    end
  end
end
