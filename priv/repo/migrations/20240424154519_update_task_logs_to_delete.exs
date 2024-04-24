defmodule BikeBrigade.Repo.Migrations.UpdateTaskLogsToDelete do
  use Ecto.Migration

  def change do
    alter table(:task_assignment_logs) do
      modify(:task_id, references(:tasks, on_delete: :delete_all), from: references(:tasks))
      modify(:rider_id, references(:riders, on_delete: :delete_all), from: references(:riders))
      modify(:user_id, references(:users, on_delete: :delete_all), from: references(:users))
    end
  end
end
