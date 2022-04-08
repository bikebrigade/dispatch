defmodule BikeBrigade.Locations.Neighborhood do
  use BikeBrigade.Schema

  schema "toronto_neighborhoods" do
    field :name, :string
    # Not including because we use it only in the database
    # field :geom, :geometry
  end
end
