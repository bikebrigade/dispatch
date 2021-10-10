defmodule BikeBrigade.Analytics.Task do
  use BikeBrigade.Schema
  import Ecto.Changeset

  schema "analytics_tasks" do
    field :delivery_date, :date
    field :delivery_distance, :integer
    field :delivery_window, :string
    field :onfleet_dropoff_id, :string
    field :onfleet_pickup_id, :string
    field :organiation_name, :string
    field :other_items, :string
    field :request_type, :string
    field :rider_notes, :string
    field :size, :integer
    field :submitted_on, :utc_datetime
    field :rider_id, :id
    field :pickup_contact_id, :id
    field :pickup_address, :id
    field :dropoff_contact_id, :id
    field :dropoff_address, :id

    timestamps()
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [:rider_notes, :submitted_on, :organiation_name, :onfleet_pickup_id, :onfleet_dropoff_id, :request_type, :other_items, :size, :delivery_date, :delivery_window, :delivery_distance])
    |> validate_required([:rider_notes, :submitted_on, :organiation_name, :onfleet_pickup_id, :onfleet_dropoff_id, :request_type, :other_items, :size, :delivery_date, :delivery_window, :delivery_distance])
  end
end
