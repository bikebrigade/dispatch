defmodule BikeBrigade.Delivery.TaskItem do
  use BikeBrigade.Schema

  import Ecto.Changeset

  alias BikeBrigade.Delivery.{Task, Item}

  schema "tasks_items" do
    field :count, :integer, default: 1

    belongs_to :task, Task
    belongs_to :item, Item

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:task_id, :item_id, :count])
    |> validate_required([:item_id, :count])
    # TODO: this unique constraint isn't in the database
    # make it do the magic where it adds things?
    |> unique_constraint([:task_id, :item_id])
  end
end
