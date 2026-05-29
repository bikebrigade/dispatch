defmodule BikeBrigade.Locations.CommunityFridge do
  use Ecto.Schema
  import Ecto.Changeset

  alias BikeBrigade.Locations.Location
  alias BikeBrigade.Delivery.Task

  schema "community_fridges" do
    field :active, :boolean, default: true
    field :name, :string
    field :description, :string
    field :photo, :string
    field :pair_preferred, :boolean, default: false
    belongs_to :location, Location

    has_many :tasks, Task

    timestamps()
  end

  @doc false
  def changeset(community_fridge, attrs) do
    community_fridge
    |> cast(attrs, [:name, :description, :photo, :active, :pair_preferred, :location_id])
    |> validate_required([:name, :location_id])
    |> assoc_constraint(:location)
  end
end
