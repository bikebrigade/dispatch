defmodule BikeBrigade.Analytics.Address do
  use BikeBrigade.Schema
  import Ecto.Changeset

  schema "analytics_addresses" do
    field :city, :string
    field :country, :string
    field :geo, Geo.PostGIS.Geometry
    field :line1, :string
    field :line2, :string
    field :postal, :string
    field :province, :string

    timestamps()
  end

  @doc false
  def changeset(address, attrs) do
    address
    |> cast(attrs, [:line1, :line2, :city, :province, :postal, :country, :geo])
    |> validate_required([:line1, :line2, :city, :province, :postal, :country, :geo])
  end
end
