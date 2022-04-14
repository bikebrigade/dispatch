defmodule BikeBrigade.Riders.Rider do
  use BikeBrigade.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false
  import EctoEnum

  alias BikeBrigade.Locations.Location
  alias BikeBrigade.Repo
  alias BikeBrigade.Riders.{Tag, RidersTag, RiderLatestCampaign}
  alias BikeBrigade.Delivery.{Task, CampaignRider}
  alias BikeBrigade.Stats.RiderStats

  defenum(OnfleetAccountStatusEnum, invited: "invited", accepted: "accepted")

  defenum(MailchimpStatusEnum,
    subscribed: "subscribed",
    unsubscribed: "unsubscribed",
    cleaned: "cleaned",
    pending: "pending",
    transactional: "transactional"
  )

  defenum(CapacityEnum, small: 1, medium: 4, large: 9)

  defmodule Flags do
    use BikeBrigade.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :opt_in_to_new_number, :boolean, default: true
      field :initial_message_sent, :boolean, default: false
    end

    def changeset(flags, attrs \\ %{}) do
      flags
      |> cast(attrs, [:opt_in_to_new_number, :initial_message_sent])
      |> validate_required([:opt_in_to_new_number, :initial_message_sent])
    end
  end

  schema "riders" do
    field :availability, :map
    field :capacity, CapacityEnum

    field :deliveries_completed, :integer
    field :email, :string
    field :mailchimp_id, :string
    field :mailchimp_status, MailchimpStatusEnum
    field :max_distance, :integer
    field :name, :string
    field :phone, BikeBrigade.EctoPhoneNumber.Canadian
    field :text_based_itinerary, :boolean, default: false
    field :pronouns, :string
    field :signed_up_on, :utc_datetime
    field :last_safety_check, :date
    field :internal_notes, :string

    belongs_to :location, Location, on_replace: :update

    # TODO look into removing these virtuals
    field :distance, :integer, virtual: true
    field :remaining_distance, :integer, virtual: true
    field :task_count, :integer, virtual: true
    field :task_notes, :string, virtual: true
    field :task_capacity, :integer, virtual: true
    field :task_enter_building, :boolean, virtual: true
    field :delivery_url_token, :string, virtual: true
    field :pickup_window, :string, virtual: true

    has_many :assigned_tasks, Task, foreign_key: :assigned_rider_id
    has_many :campaign_riders, CampaignRider

    has_many :campaigns,
      through: [:campaign_riders, :campaign],
      preload_order: [:desc, :delivery_start]

    has_one :rider_latest_campaign, RiderLatestCampaign
    has_one :latest_campaign, through: [:rider_latest_campaign, :campaign]

    has_one :total_stats, RiderStats, where: [program_id: nil]

    has_many :program_stats, RiderStats,
      where: [program_id: {:not, nil}],
      preload_order: [desc: :campaign_count]

    embeds_one :flags, Flags, on_replace: :update

    # TODO cleanup
    many_to_many :tags, Tag, join_through: RidersTag, on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(rider, attrs) do
    rider
    |> cast(attrs, [
      :name,
      :email,
      :phone,
      :pronouns,
      :availability,
      :capacity,
      :max_distance,
      :signed_up_on,
      :mailchimp_id,
      :mailchimp_status,
      :last_safety_check,
      :internal_notes,
      :text_based_itinerary
    ])
    |> cast_embed(:flags)
    |> cast_assoc(:location)
    |> update_change(:email, &String.downcase/1)
    |> validate_required([
      :name,
      :email,
      :phone,
      :availability,
      :capacity,
      :max_distance,
      :location
    ])
    |> validate_change(:email, fn :email, email ->
      if String.contains?(email, "@") do
        []
      else
        [email: "is invalid"]
      end
    end)
    |> unique_constraint(:phone)
    |> unique_constraint(:email)
    |> set_signed_up_on()
  end

  def tags_changeset(changeset, tags) do
    changeset
    |> put_assoc(:tags, insert_and_get_all_tags(tags))
  end

  def set_signed_up_on(%Ecto.Changeset{} = changeset) do
    case fetch_field(changeset, :signed_up_on) do
      {_, signed_up_on} when not is_nil(signed_up_on) -> changeset
      _ -> put_change(changeset, :signed_up_on, DateTime.utc_now() |> DateTime.truncate(:second))
    end
  end

  defp insert_and_get_all_tags(names) do
    # Adapted from https://hexdocs.pm/ecto/constraints-and-upserts.html#upserts-and-insert_all

    Repo.insert_all(
      Tag,
      for name <- names do
        name = String.trim(name)

        %{
          name: name,
          inserted_at: {:placeholder, :timestamp},
          updated_at: {:placeholder, :timestamp}
        }
      end,
      placeholders: %{timestamp: DateTime.utc_now()},
      on_conflict: :nothing
    )

    Repo.all(from t in Tag, where: t.name in ^names)
  end
end
