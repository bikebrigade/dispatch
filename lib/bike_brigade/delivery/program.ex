defmodule BikeBrigade.Delivery.Program do
  use BikeBrigade.Schema
  import Ecto.Changeset
  import EctoEnum
  import Crontab.CronExpression

  alias BikeBrigade.Delivery.{Item, Campaign, ProgramLatestCampaign}

  defenum(SpreadsheetLayout,
    foodshare: "foodshare",
    map: "map"
  )

  defmodule Schedule do
    use BikeBrigade.Schema

    embedded_schema do
      field :cron, Ecto.Cron, default: ~e[0 12 * * 3 *]
      field :duration, :integer, default: 60
    end

    def changeset(schedule, attrs \\ %{}) do
      schedule
      |> cast(attrs, [:cron, :duration])
      |> validate_required([:cron, :duration])
    end
  end

  schema "programs" do
    field :name, :string
    field :contact_name, :string
    field :contact_email, :string
    field :contact_phone, BikeBrigade.EctoPhoneNumber.Canadian
    field :campaign_blurb, :string
    field :description, :string
    field :spreadsheet_layout, SpreadsheetLayout, default: :foodshare
    field :active, :boolean, default: true
    field :start_date, :date
    field :photo_description, :string
    field :photos, {:array, :string}, default: []

    # Default to public false before we launch
    field :public, :boolean, default: false
    field :hide_pickup_address, :boolean, default: false

    # TODO: this is me trying out virtual fields again
    field :campaign_count, :integer, virtual: true

    embeds_many :schedules, Schedule, on_replace: :delete

    has_one :program_latest_campaign, ProgramLatestCampaign
    has_one :latest_campaign, through: [:program_latest_campaign, :campaign]

    belongs_to :lead, BikeBrigade.Accounts.User, on_replace: :nilify
    has_many :campaigns, Campaign, preload_order: [desc: :delivery_start]

    has_many :items, Item, on_replace: :delete_if_exists
    belongs_to :default_item, Item

    timestamps()
  end

  @doc false
  def changeset(program, attrs) do
    program
    |> cast(attrs, [
      :active,
      :name,
      :contact_name,
      :contact_email,
      :contact_phone,
      :campaign_blurb,
      :default_item_id,
      :description,
      :lead_id,
      :public,
      :hide_pickup_address,
      :spreadsheet_layout,
      :start_date,
      :photo_description,
      :photos
    ])
    |> validate_required([:name, :start_date])
    |> foreign_key_constraint(:lead_id)
    |> cast_embed(:schedules)
    |> cast_assoc(:items)
  end
end
