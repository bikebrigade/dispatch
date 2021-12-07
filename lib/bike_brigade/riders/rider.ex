defmodule BikeBrigade.Riders.Rider do
  use BikeBrigade.Schema
  import Ecto.Changeset
  import EctoEnum

  alias BikeBrigade.Repo
  alias BikeBrigade.Riders.{Tag, RidersTag}
  alias BikeBrigade.Delivery.{Task, CampaignRider}
  alias BikeBrigade.Stats.RiderStats

  alias BikeBrigade.Geocoder

  defenum OnfleetAccountStatusEnum, invited: "invited", accepted: "accepted"
  defenum MailchimpStatusEnum, subscribed: "subscribed", unsubscribed: "unsubscribed", cleaned: "cleaned", pending: "pending", transactional: "transactional"
  defenum CapacityEnum, small: 1, medium: 4, large: 9

  defmodule Flags do
    use BikeBrigade.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema  do
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
    field :address, :string
    field :address2, :string
    field :availability, :map
    field :capacity, CapacityEnum
    field :city, :string
    field :country, :string
    field :deliveries_completed, :integer
    field :email, :string
    field :location, Geo.PostGIS.Geometry
    field :mailchimp_id, :string
    field :mailchimp_status, MailchimpStatusEnum
    field :max_distance, :integer
    field :name, :string
    field :onfleet_id, :string
    field :onfleet_account_status, OnfleetAccountStatusEnum
    field :phone, BikeBrigade.EctoPhoneNumber.Canadian
    field :postal, :string
    field :pronouns, :string
    field :province, :string
    field :signed_up_on, :utc_datetime
    field :last_safety_check, :date

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
    has_many :campaigns, through: [:campaign_riders, :campaign]
    has_one :stats, RiderStats

    embeds_one :flags, Flags, on_replace: :update

    # TODO cleanup
    many_to_many :tags, Tag, join_through: RidersTag

    timestamps()
  end

  @doc false
  def changeset(rider, attrs) do
    cs = rider
    |> cast(attrs, [:name, :email, :address, :address2, :city, :deliveries_completed, :location, :province, :postal, :country, :onfleet_id, :onfleet_account_status, :phone, :pronouns, :availability, :capacity, :max_distance, :signed_up_on, :mailchimp_id, :mailchimp_status, :last_safety_check])
    |> cast_embed(:flags)
    |> update_change(:email, &String.downcase/1)
    |> validate_required([:name, :email, :city, :province, :postal, :country, :phone, :availability, :capacity, :max_distance])
    |> validate_change(:email, fn :email, email  ->
      if String.contains?(email, "@") do
        []
      else
        [email: "is invalid"]
      end
    end)
    |> unique_constraint(:phone)
    |> unique_constraint(:email)
    |> set_signed_up_on()
    |> fetch_location()

    if attrs[:tags] do
      put_assoc(cs, :tags, Enum.map(Access.get(attrs, :tags, []), &get_or_insert_tag/1), on_replace: :update)
    else
      cs
    end
  end

  def set_signed_up_on(%Ecto.Changeset{} = changeset) do
    case fetch_field(changeset, :signed_up_on) do
      {_, signed_up_on} when not is_nil(signed_up_on)-> changeset
      _ -> put_change(changeset, :signed_up_on, DateTime.utc_now() |> DateTime.truncate(:second))
    end
  end

  defp fetch_location(%Ecto.Changeset{} = changeset) do
    # We only fetch the location if we changed the address but *not* the location[]
    with  {:data, _location} <- fetch_field(changeset, :location),
          {:changes, address} <- fetch_field(changeset, :address),
          {_, city} <- fetch_field(changeset, :city),
          {_, postal} <- fetch_field(changeset, :postal),
          {_, province} <- fetch_field(changeset, :province),
          {_, country} <- fetch_field(changeset, :country),
          {:ok, location} <- Ge3ocoder.lookup("#{address} #{city} #{postal} #{province} #{country}")
    do
      location = %Geo.Point{
        coordinates: {location.lon, location.lat}
      }

      changeset
      |> put_change(:location, location)
    else
      _ -> changeset
    end
  end

  defp get_or_insert_tag(name) do
    Repo.insert!(
      %Tag{name: name},
      on_conflict: [set: [name: name]],
      conflict_target: :name
    )
  end
end
