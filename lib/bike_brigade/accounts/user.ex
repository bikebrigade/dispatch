defmodule BikeBrigade.Accounts.User do
  use BikeBrigade.Schema
  import Ecto.Changeset

  alias BikeBrigade.Riders.Rider

  alias BikeBrigade.EctoPhoneNumber

  schema "users" do
    field :email, :string
    field :name, :string
    field :phone, EctoPhoneNumber.Canadian
    field :is_dispatcher, :boolean, default: false
    field :signature_on_messages, :string
    belongs_to :rider, Rider

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :phone])
    |> validate_required([:name, :email, :phone])
    |> unique_constraint(:phone)
    |> unique_constraint(:email)
  end

  @doc "This changeset is to be used by admin users"
  def admin_changeset(user, attrs) do
    user
    |> changeset(attrs)
    |> cast(attrs, [:is_dispatcher, :rider_id, :signature_on_messages])
  end
end
