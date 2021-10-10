defmodule BikeBrigade.Analytics.Contact do
  use BikeBrigade.Schema
  import Ecto.Changeset

  schema "analytics_contacts" do
    field :email, :string
    field :name, :string
    field :phone, :string
    field :address, :id

    timestamps()
  end

  @doc false
  def changeset(contact, attrs) do
    contact
    |> cast(attrs, [:name, :email, :phone])
    |> validate_required([:name, :email, :phone])
  end
end
