defmodule BikeBrigade.Messaging.Banner do
  use BikeBrigade.Schema
  import Ecto.Changeset

  alias BikeBrigade.Accounts.User

  schema "banners" do
    field :message, :string
    field :turn_on_at, :utc_datetime
    field :turn_off_at, :utc_datetime
    belongs_to :created_by_user, User
  end

  @doc false
  def changeset(banner, attrs) do
    banner
    |> cast(attrs, [
      :message,
      :created_by,
      :turn_on_at,
      :turn_off_at,
    ])
    |> validate_required([:message, :turn_on_at, :created_by, :turn_off_at])
  end
  
end
