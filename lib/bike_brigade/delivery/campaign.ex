defmodule BikeBrigade.Delivery.Campaign do
  use BikeBrigade.Schema

  import Ecto.Changeset
  import EctoEnum

  alias BikeBrigade.Riders.Rider
  alias BikeBrigade.Delivery.{Task, CampaignRider, Program}

  alias BikeBrigade.Messaging
  alias BikeBrigade.Messaging.SmsMessage

  alias BikeBrigade.Location
  alias BikeBrigade.Geocoder

  defenum(RiderSpreadsheetLayout, non_foodshare: 0, foodshare: 1)

  @fields [
    :name,
    :delivery_date,
    :delivery_start,
    :delivery_end,
    :details,
    :pickup_address,
    :pickup_address2,
    :pickup_city,
    :pickup_country,
    :pickup_location,
    :pickup_postal,
    :pickup_province,
    :pickup_window,
    :rider_spreadsheet_id,
    :rider_spreadsheet_layout,
    :program_id
  ]

  schema "campaigns" do
    field(:name, :string)
    field(:delivery_date, :date)
    field(:delivery_start, :utc_datetime)
    field(:delivery_end, :utc_datetime)
    field(:details, :string)
    field(:pickup_address, :string)
    field(:pickup_address2, :string)
    field(:pickup_city, :string)
    field(:pickup_country, :string)
    field(:pickup_location, Geo.PostGIS.Geometry)
    field(:pickup_postal, :string)
    field(:pickup_province, :string)
    field(:pickup_window, :string)
    field(:rider_spreadsheet_id, :string)
    field(:rider_spreadsheet_layout, RiderSpreadsheetLayout)

    belongs_to(:instructions_template, Messaging.Template, on_replace: :update)
    belongs_to(:program, Program)
    has_one(:scheduled_message, Messaging.ScheduledMessage, on_replace: :delete)

    # todo possibly a has_many
    has_many(:tasks, Task)
    has_many(:campaign_riders, CampaignRider)
    many_to_many(:riders, Rider, join_through: CampaignRider)

    field :total_riders, :integer, virtual: true
    field :total_tasks, :integer, virtual: true

    field :delivery_url_token, :string, virtual: true

  #  field :campaign_message_id, :integer, virtual: true
    belongs_to :latest_message, SmsMessage, define_field: false

    timestamps()
  end

  # TODO: maybe call this something like changeset! because it makes an API call
  def changeset(struct, params \\ %{}) do
    changeset =
      struct
      |> cast(params, @fields)
      |> fetch_pickup_location()

    changeset
    |> cast_assoc(:tasks, with: Task.changeset_for_campaign(changeset), required: false)
    |> cast_assoc(:riders, required: false)
    |> cast_assoc(:instructions_template, required: false)
    |> cast_assoc(:scheduled_message, required: false)
    |> validate_required([:delivery_start, :delivery_end, :pickup_location])
    # TODO is this actually unique
    |> unique_constraint(:name)
  end

  # TODO: this is acopy of the one from Task, make this a shared lib
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
          }} <- Geocoder.lookup_toronto(address) do
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

  def fields_for(campaign) do
    Map.take(campaign, @fields)
  end
end
