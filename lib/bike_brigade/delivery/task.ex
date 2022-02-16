defmodule BikeBrigade.Delivery.Task do
  use BikeBrigade.Schema

  import Ecto.Changeset
  import EctoEnum

  alias BikeBrigade.EctoPhoneNumber
  alias BikeBrigade.Riders.Rider
  alias BikeBrigade.Delivery.{Campaign, Item, TaskItem}
  alias BikeBrigade.Location
  alias BikeBrigade.Geocoder

  defenum(DeliveryStatusEnum,
    pending: "pending",
    picked_up: "picked_up",
    completed: "completed",
    failed: "failed",
    removed: "removed"
  )

  @fields [
    :dropoff_address,
    :dropoff_address2,
    :dropoff_city,
    :dropoff_name,
    :dropoff_phone,
    :dropoff_postal,
    :dropoff_province,
    :delivery_status,
    :delivery_status_notes,
    :partner_tracking_id,
    :pickup_address,
    :pickup_address2,
    :pickup_city,
    :pickup_country,
    :pickup_location,
    :pickup_postal,
    :pickup_province,
    :rider_notes,
    :assigned_rider_id,
    :campaign_id
  ]

  @embedded_fields [
    :dropoff_location
  ]

  # TODO we're missing a dropoff_country field :joy:
  schema "tasks" do
    field :delivery_distance, :integer
    # TODO: rename to delivery_instructions
    field :rider_notes, :string
    field :dropoff_address, :string
    field :dropoff_address2, :string
    field :dropoff_city, :string

    field :dropoff_name, :string
    field :dropoff_phone, EctoPhoneNumber.Canadian
    field :dropoff_postal, :string
    field :dropoff_province, :string
    field :delivery_status, DeliveryStatusEnum, default: :pending
    field :delivery_status_notes, :string
    field :partner_tracking_id, :string
    field :pickup_address, :string
    field :pickup_address2, :string
    field :pickup_city, :string
    field :pickup_country, :string
    field :pickup_location, Geo.PostGIS.Geometry
    field :pickup_postal, :string
    field :pickup_province, :string

    embeds_one :dropoff_location, Location, on_replace: :update

    belongs_to :assigned_rider, Rider, on_replace: :nilify
    belongs_to :campaign, Campaign
    has_many :task_items, TaskItem, on_replace: :delete_if_exists
    many_to_many :items, Item, join_through: TaskItem

    timestamps()
  end

  def changeset_for_campaign(campaign_changeset) do
    fn task, attrs ->
      with {_, pickup_location} <- fetch_field(campaign_changeset, :location) do
        attrs =
          %{
            pickup_address: pickup_location.address,
            pickup_city: pickup_location.city,
            pickup_country: pickup_location.country,
            pickup_location: pickup_location.coords,
            pickup_postal: pickup_location.postal,
            pickup_province: pickup_location.province
          }
          |> Map.merge(attrs)

        changeset(task, attrs)
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
    |> cast_embed(:dropoff_location, location_opts)
    |> validate_required([
      :delivery_status,
      :dropoff_location,
      :dropoff_name,
      # :dropoff_phone,
      :pickup_address,
      :pickup_city,
      :pickup_country,
      :pickup_postal
    ])
    |> cast_assoc(:task_items)
  end

  def fields_for(task) do
    embedded =
      for k <- @embedded_fields, into: %{} do
        value =
          Map.get(task, k)
          |> Map.from_struct()

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
