defmodule BikeBrigade.Delivery.Task do
  use BikeBrigade.Schema

  import Ecto.Changeset
  import EctoEnum

  alias BikeBrigade.EctoPhoneNumber
  alias BikeBrigade.Riders.Rider
  alias BikeBrigade.Delivery.{Campaign, Item, TaskItem}
  alias BikeBrigade.Locations.Location

  defenum(DeliveryStatusEnum,
    pending: "pending",
    picked_up: "picked_up",
    completed: "completed",
    failed: "failed",
    removed: "removed"
  )

  @fields [
    :dropoff_name,
    :dropoff_phone,
    :delivery_status,
    :delivery_status_notes,
    :partner_tracking_id,
    :rider_notes,
    :assigned_rider_id,
    :campaign_id
  ]

  @embedded_fields [
    :pickup_location,
    :dropoff_location
  ]
  schema "tasks" do
    # TODO: rename to delivery_instructions
    field :rider_notes, :string

    field :dropoff_name, :string
    field :dropoff_phone, EctoPhoneNumber.Canadian

    field :delivery_status, DeliveryStatusEnum, default: :pending
    field :delivery_status_notes, :string
    field :partner_tracking_id, :string

    field :delivery_distance, :integer, virtual: true

    belongs_to :dropoff_location, Location, on_replace: :update
    belongs_to :pickup_location, Location, on_replace: :update

    belongs_to :assigned_rider, Rider, on_replace: :nilify
    belongs_to :campaign, Campaign
    has_many :task_items, TaskItem, on_replace: :delete_if_exists
    many_to_many :items, Item, join_through: TaskItem

    timestamps()
  end

  def changeset_for_campaign(campaign_changeset, opts \\ []) do
    fn task, attrs ->
      with {_, campaign_location} <- fetch_field(campaign_changeset, :location) do
        task
        |> change()
        |> put_assoc(:pickup_location, campaign_location)
        |> changeset(attrs, opts)
      end
    end
  end

  def changeset(task, attrs, opts \\ []) do
    location_opts =
      if Keyword.get(opts, :geocode, false) do
        [with: &Location.geocoding_changeset/2]
      else
        []
      end

    task
    |> cast(attrs, @fields)
    |> cast_assoc(:pickup_location, location_opts)
    |> cast_assoc(:dropoff_location, location_opts)
    |> validate_required([
      :delivery_status,
      # :dropoff_location_id,
      :dropoff_name
      # :dropoff_phone,
      # :pickup_location_id
    ])
    |> assoc_constraint(:dropoff_location)
    |> cast_assoc(:task_items)
  end

  def fields_for(task) do
    # TODO the caller has to preload these :(
    embedded =
      for k <- @embedded_fields, into: %{} do
        value =
          Map.get(task, k)
          |> Map.from_struct()
          |> Map.delete(:id)

        {k, value}
      end

    fields =
      @fields
      |> Enum.filter(fn field ->
        field not in [:submitted_on, :assigned_rider_id, :campaign_id]
      end)

    Map.take(task, fields)
    |> Map.merge(embedded)
  end
end
