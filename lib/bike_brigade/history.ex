defmodule BikeBrigade.History do
  import Ecto.Query, warn: false
  alias BikeBrigade.Repo

  alias BikeBrigade.History.TaskAssignmentLog

  @doc """
  List all task assignment logs

  Currently this table is used for analytics and not exposed in the app.
  """
  def list_task_assignment_logs() do
    Repo.all(TaskAssignmentLog)
  end

  def create_task_assignment_log(attrs \\ %{}) do
    %TaskAssignmentLog{timestamp: DateTime.utc_now()}
    |> TaskAssignmentLog.changeset(attrs)
    |> Repo.insert()
  end
end
