defmodule BikeBrigade.Repo.Migrations.CreateTaskAssgignmentLog do
  use Ecto.Migration

  def change do
    create table(:task_assignment_logs) do
      add :task_id, references(:tasks)
      add :rider_id, references(:riders)
      add :user_id, references(:users)
      add :timestamp, :utc_datetime_usec
      add :action, :string

      timestamps()
    end
  end
end
