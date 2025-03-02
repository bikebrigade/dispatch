defmodule BikeBrigade.Delivery.Announcement do
  use Ecto.Schema
  import Ecto.Changeset

  schema "announcements" do
    field :message, :string
    field :turn_on_at, :utc_datetime_usec
    field :turn_off_at, :utc_datetime_usec
    belongs_to :user, BikeBrigade.Accounts.User, foreign_key: :created_by

    timestamps()
  end

  @doc false
  def changeset(announcement, attrs) do
    announcement
    |> cast(attrs, [:message, :turn_on_at, :turn_off_at, :created_by])
    |> validate_required([:message, :turn_on_at, :turn_off_at, :created_by ])
  end


end
