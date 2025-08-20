defmodule BikeBrigade.Notifications.Banner do
  use BikeBrigade.Schema
  import Ecto.Changeset

  alias BikeBrigade.Accounts.User

  schema "banners" do
    field :message, :string
    field :turn_on_at, :utc_datetime
    field :turn_off_at, :utc_datetime
    field :enabled, :boolean, default: true
    belongs_to :created_by, User
  end

  @doc false
  def changeset(banner, attrs) do
    banner
    |> cast(attrs, [
      :message,
      :created_by_id,
      :turn_on_at,
      :turn_off_at,
      :enabled
    ])
    |> validate_required([:message, :created_by_id, :turn_on_at, :turn_off_at])
    |> validate_time_range()
    |> foreign_key_constraint(:created_by_id)
  end

  defp validate_time_range(changeset) do
    turn_on_at = get_field(changeset, :turn_on_at)
    turn_off_at = get_field(changeset, :turn_off_at)

    if turn_on_at && turn_off_at && DateTime.compare(turn_on_at, turn_off_at) != :lt do
      add_error(changeset, :turn_off_at, "must be after turn on time")
    else
      changeset
    end
  end
end
