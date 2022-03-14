defmodule BikeBrigade.Accounts.User do
  use BikeBrigade.Schema
  import Ecto.Changeset

  alias BikeBrigade.Riders.Rider

  alias BikeBrigade.EctoPhoneNumber

  schema "users" do
    field :email, :string
    field :name, :string
    field :phone, EctoPhoneNumber.Canadian
    belongs_to :rider, Rider

    timestamps()
  end

  # TODO: when casting :rider_id make this an admin_changeset!
  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :phone])
    |> validate_required([:name, :email, :phone])
    |> unique_constraint(:phone)
    |> unique_constraint(:email)
  end
end
