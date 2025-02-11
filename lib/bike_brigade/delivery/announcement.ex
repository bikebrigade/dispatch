defmodule BikeBrigade.Delivery.Announcement do
  use Ecto.Schema
  import Ecto.Changeset

  schema "announcements" do
    field :message, :string
    field :turn_on_at, :utc_datetime_usec
    field :turn_off_at, :utc_datetime_usec
    field :created_by, :id

    timestamps()
  end

  @doc false
  def changeset(announcement, attrs) do
    announcement
    |> cast(attrs, [:message, :turn_on_at, :turn_off_at])
    |> validate_required([:message, :turn_on_at, :turn_off_at])
  end
end
