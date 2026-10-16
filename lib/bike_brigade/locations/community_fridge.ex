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

    belongs_to :location, Location, on_replace: :update

    timestamps()
  end

  def changeset(community_fridge, params) do
    community_fridge
    |> cast(params, @fields)
    |> cast_assoc(:location)
    |> validate_required([:name])
  end
end
