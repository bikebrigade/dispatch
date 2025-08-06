defmodule BikeBrigade.Messaging.Banner do
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
    |> foreign_key_constraint(:created_by_id)
  end
end
