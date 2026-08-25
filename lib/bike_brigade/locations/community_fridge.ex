defmodule BikeBrigade.Locations.CommunityFridge do
  use BikeBrigade.Schema
  import Ecto.Changeset

  alias BikeBrigade.Locations.Location

  @fields [
    :name,
    :description,
    :photo,
    :active,
    :pair_preferred
  ]

  schema "community_fridges" do
    field :name, :string
    field :description, :string
    field :photo, :string
    field :active, :boolean, default: true
    field :pair_preferred, :boolean, default: false

    belongs_to :location, Location

    timestamps()
  end

  def changeset(community_fridge, attrs) do
    community_fridge
    |> cast(attrs, @fields ++ [:location_id])
    |> validate_required([:name])
    |> assoc_constraint(:location)
  end
end
