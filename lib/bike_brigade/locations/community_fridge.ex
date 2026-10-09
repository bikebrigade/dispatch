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
    |> maybe_cast_location(params)
    |> validate_required([:name])
    |> unique_constraint(:location_id)
  end

  # Only associate a location when an address is present in the params (new location),
  # or the fridge already has a location that may need updating (edit scenario).
  defp maybe_cast_location(changeset, params) do
    location_params = Map.get(params, "location") || Map.get(params, :location, %{})
    address = Map.get(location_params, "address") || Map.get(location_params, :address)
    has_existing = not is_nil(changeset.data.location_id)

    if address not in [nil, ""] || has_existing do
      cast_assoc(changeset, :location)
    else
      changeset
    end
  end
end
