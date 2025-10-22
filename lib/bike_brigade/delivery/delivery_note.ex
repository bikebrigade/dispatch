defmodule BikeBrigade.Delivery.DeliveryNote do
  use BikeBrigade.Schema

  import Ecto.Changeset

  alias BikeBrigade.Riders.Rider
  alias BikeBrigade.Delivery.Task
  alias BikeBrigade.Accounts.User

  schema "delivery_notes" do
    field :note, :string
    field :resolved_at, :utc_datetime

    belongs_to :rider, Rider
    belongs_to :task, Task
    belongs_to :resolved_by, User

    timestamps()
  end

  @doc false
  def changeset(delivery_note, attrs) do
    delivery_note
    |> cast(attrs, [:note, :rider_id, :task_id])
    |> validate_required([:note, :rider_id, :task_id])
    |> assoc_constraint(:rider)
    |> assoc_constraint(:task)
  end

  @doc false
  def resolve_changeset(delivery_note, user_id) do
    delivery_note
    |> change(%{
      resolved_at: DateTime.utc_now() |> DateTime.truncate(:second),
      resolved_by_id: user_id
    })
  end

  @doc false
  def unresolve_changeset(delivery_note) do
    delivery_note
    |> change(%{
      resolved_at: nil,
      resolved_by_id: nil
    })
  end
end
