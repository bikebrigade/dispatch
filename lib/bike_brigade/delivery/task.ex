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
    :contact_email,
    :contact_name,
    :contact_phone,
    :delivery_date,
    :delivery_window,
    :dropoff_address,
    :dropoff_address2,
    :dropoff_city,
    :dropoff_email,
    :dropoff_location,
    :dropoff_name,
    :dropoff_organization,
    :dropoff_phone,
    :dropoff_postal,
    :dropoff_province,
    :delivery_status,
    :delivery_status_notes,
    :onfleet_dropoff_id,
    :onfleet_pickup_id,
    :organization_name,
    :organization_partner,
    :other_items,
    :pickup_address,
    :pickup_address2,
    :pickup_city,
    :pickup_country,
    :pickup_location,
    :pickup_postal,
    :pickup_province,
    :request_type,
    :rider_notes,
    :size,
    :submitted_on,
    :assigned_rider_id,
    :campaign_id
  ]

  # TODO we're missing a dropoff_country field :joy:
  schema "tasks" do
    field :contact_email, :string
    field :contact_name, :string
    field :contact_phone, EctoPhoneNumber.Canadian
    field :delivery_date, :date
    field :delivery_distance, :integer
    field :delivery_window, :string
    # TODO: rename to delivery_instructions
    field :rider_notes, :string
    field :dropoff_address, :string
    field :dropoff_address2, :string
    field :dropoff_city, :string
    field :dropoff_email, :string
    field :dropoff_location, Geo.PostGIS.Geometry
    field :dropoff_name, :string
    field :dropoff_organization, :string
    field :dropoff_phone, EctoPhoneNumber.Canadian
    field :dropoff_postal, :string
    field :dropoff_province, :string
    field :delivery_status, DeliveryStatusEnum, default: :pending
    field :delivery_status_notes, :string
    field :organization_name, :string
    field :organization_partner, :string
    field :onfleet_pickup_id, :string
    field :onfleet_dropoff_id, :string
    field :other_items, :string
    field :pickup_address, :string
    field :pickup_address2, :string
    field :pickup_city, :string
    field :pickup_country, :string
    field :pickup_location, Geo.PostGIS.Geometry
    field :pickup_postal, :string
    field :pickup_province, :string
    field :request_type, :string
    field :size, :integer
    # TODO drop this or make it
    field :submitted_on, :naive_datetime

    belongs_to :assigned_rider, Rider, on_replace: :nilify
    belongs_to :campaign, Campaign
    has_many :task_items, TaskItem, on_replace: :delete_if_exists
    many_to_many :items, Item, join_through: TaskItem

    timestamps()
  end

  def changeset_for_campaign(campaign_changeset) do
    fn task, attrs ->
      with {_, delivery_date} <- fetch_field(campaign_changeset, :delivery_date),
           {_, pickup_address} <- fetch_field(campaign_changeset, :pickup_address),
           {_, pickup_address2} <- fetch_field(campaign_changeset, :pickup_address2),
           {_, pickup_city} <- fetch_field(campaign_changeset, :pickup_city),
           {_, pickup_country} <- fetch_field(campaign_changeset, :pickup_country),
           {_, pickup_location} <- fetch_field(campaign_changeset, :pickup_location),
           {_, pickup_postal} <- fetch_field(campaign_changeset, :pickup_postal),
           {_, pickup_province} <- fetch_field(campaign_changeset, :pickup_province) do
        attrs =
          %{
            delivery_date: delivery_date,
            pickup_address: pickup_address,
            pickup_address2: pickup_address2,
            pickup_city: pickup_city,
            pickup_country: pickup_country,
            pickup_location: pickup_location,
            pickup_postal: pickup_postal,
            pickup_province: pickup_province
          }
          |> Map.merge(attrs)

        changeset(task, attrs)
      end
    end
  end

  def changeset(task, attrs) do
    task
    |> cast(attrs, @fields)
    |> fetch_pickup_location()
    |> fetch_dropoff_location()
    |> validate_required([
      :delivery_status,
      :dropoff_address,
      :dropoff_city,
      :dropoff_location,
      :dropoff_name,
      # :dropoff_phone,
      :dropoff_postal,
      :dropoff_province,
      :pickup_address,
      :pickup_city,
      :pickup_country,
      :pickup_postal
    ])
    |> cast_assoc(:task_items)
  end

  def fetch_pickup_location(%Ecto.Changeset{} = changeset) do
    # We only fetch the location if we changed the address but *not* the location[]
    with {:data, _location} <- fetch_field(changeset, :pickup_location),
         {:changes, address} <- fetch_field(changeset, :pickup_address),
         {:ok,
          %Location{
            lat: lat,
            lon: lon,
            city: location_city,
            postal: location_postal,
            province: location_province,
            country: location_country
          }} <- Geocoder.lookup(address) do
      pickup_location = %Geo.Point{
        coordinates: {lon, lat}
      }

      pickup_city =
        case fetch_field(changeset, :pickup_city) do
          {:changes, city} -> city
          {:data, _} -> location_city
        end

      pickup_postal =
        case fetch_field(changeset, :pickup_postal) do
          {:changes, postal} -> postal
          {:data, _} -> location_postal
        end

      pickup_province =
        case fetch_field(changeset, :pickup_province) do
          {:changes, province} -> province
          {:data, _} -> location_province
        end

      pickup_country =
        case fetch_field(changeset, :pickup_country) do
          {:changes, country} -> country
          {:data, _} -> location_country
        end

      changeset
      |> put_change(:pickup_location, pickup_location)
      |> put_change(:pickup_city, pickup_city)
      |> put_change(:pickup_postal, pickup_postal)
      |> put_change(:pickup_province, pickup_province)
      |> put_change(:pickup_country, pickup_country)
    else
      {:error, reason} ->
        # We aren't getting enough info from the address which means it must be invalid
        add_error(changeset, :pickup_address, reason)

      _ ->
        changeset
    end
  end

  def fetch_dropoff_location(%Ecto.Changeset{} = changeset) do
    # We only fetch the location if we changed the address but *not* the location[]
    with {:data, _location} <- fetch_field(changeset, :dropoff_location),
         {:changes, address} <- fetch_field(changeset, :dropoff_address),
         {:ok,
          %Location{
            lat: lat,
            lon: lon,
            city: location_city,
            postal: location_postal,
            province: location_province,
            country: _location_country
          }} <- Geocoder.lookup(address) do
      dropoff_location = %Geo.Point{
        coordinates: {lon, lat}
      }

      dropoff_city =
        case fetch_field(changeset, :dropoff_city) do
          {:changes, city} -> city
          {:data, _} -> location_city
        end

      dropoff_postal =
        case fetch_field(changeset, :dropoff_postal) do
          {:changes, postal} -> postal
          {:data, _} -> location_postal
        end

      dropoff_province =
        case fetch_field(changeset, :dropoff_province) do
          {:changes, province} -> province
          {:data, _} -> location_province
        end

      changeset
      |> put_change(:dropoff_location, dropoff_location)
      |> put_change(:dropoff_city, dropoff_city)
      |> put_change(:dropoff_postal, dropoff_postal)
      |> put_change(:dropoff_province, dropoff_province)
    else
      {:ok, reason} ->
        # We aren't getting enough info from the address which means it must be invalid
        add_error(changeset, :dropoff_address, reason)

      _ ->
        changeset
    end
  end

  def fields_for(task) do
    fields = @fields
    |> Enum.filter(fn field -> field not in [:submitted_on, :assigned_rider_id, :campaign_id] end)
    Map.take(task, fields)
  end
end
