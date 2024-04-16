defmodule BikeBrigade.Delivery.TaskAssignmentLog do
  use BikeBrigade.Schema

  import Ecto.Changeset

  alias BikeBrigade.Delivery.Task
  alias BikeBrigade.Riders.Rider
  alias BikeBrigade.Accounts.User

  schema "task_assignment_logs" do
    belongs_to :task, Task
    belongs_to :rider, Rider
    belongs_to :user, User

    field :timestamp, :utc_datetime_usec
    field :action, Ecto.Enum, values: [:assigned, :unassigned]

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :task_id,
      :rider_id,
      :user_id,
      :timestamp,
      :action
    ])
    |> validate_required([:task_id, :rider_id, :user_id, :timestamp, :action])
    |> validate_inclusion(:action, [:assigned, :unassigned])
  end
end
