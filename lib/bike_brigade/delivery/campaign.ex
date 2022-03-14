defmodule BikeBrigade.Delivery.Campaign do
  use BikeBrigade.Schema

  import Ecto.Changeset
  import EctoEnum

  alias BikeBrigade.Riders.Rider
  alias BikeBrigade.Delivery.{Task, CampaignRider, Program, CampaignLatestMessage}

  alias BikeBrigade.Messaging

  alias BikeBrigade.Location

  alias BikeBrigade.Stats.CampaignStats

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

  @embedded_fields [
    :location
  ]

  schema "campaigns" do
    field :name, :string
    field :delivery_date, :date
    field :delivery_start, :utc_datetime
    field :delivery_end, :utc_datetime
    field :details, :string
    # TODO remove
    field :pickup_address, :string
    # TODO remove
    field :pickup_address2, :string
    # TODO remove
    field :pickup_city, :string
    # TODO remove
    field :pickup_country, :string
    # TODO remove
    field :pickup_location, Geo.PostGIS.Geometry
    # TODO remove
    field :pickup_postal, :string
    # TODO remove
    field :pickup_province, :string
    # TODO remove
    field :pickup_window, :string
    # TODO remove
    field :rider_spreadsheet_id, :string
    # TODO remove
    field :rider_spreadsheet_layout, RiderSpreadsheetLayout

    embeds_one :location, Location, on_replace: :update

    belongs_to :instructions_template, Messaging.Template, on_replace: :update
    belongs_to :program, Program
    has_one :scheduled_message, Messaging.ScheduledMessage, on_replace: :delete

    # todo possibly a has_many
    has_many :tasks, Task
    has_many :campaign_riders, CampaignRider
    many_to_many :riders, Rider, join_through: CampaignRider

    has_one :stats, CampaignStats

    field :delivery_url_token, :string, virtual: true

    has_one :campaign_latest_message, CampaignLatestMessage
    has_one :latest_message, through: [:campaign_latest_message, :sms_message]

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    changeset =
      struct
      |> cast(params, @fields)
      |> cast_embed(:location)

    changeset
    |> cast_assoc(:tasks, with: Task.changeset_for_campaign(changeset), required: false)
    |> cast_assoc(:riders, required: false)
    |> cast_assoc(:instructions_template, required: false)
    |> cast_assoc(:scheduled_message, required: false)
    |> validate_required([:delivery_start, :delivery_end, :location])
    # TODO is this actually unique
    |> unique_constraint(:name)
  end

  def fields_for(campaign) do
    embedded =
      for k <- @embedded_fields, into: %{} do
        value =
          Map.get(campaign, k)
          |> Map.from_struct()

        {k, value}
      end

    Map.take(campaign, @fields)
    |> Map.merge(embedded)
  end
end
