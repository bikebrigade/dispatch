defmodule BikeBrigade.Locations.LocationNeighborhood do
  use BikeBrigade.Schema

  alias BikeBrigade.Locations.Location
  alias BikeBrigade.Locations.Neighborhood

  @primary_key false
  schema "locations_neighborhoods" do
    belongs_to :location, Location, primary_key: true
    belongs_to :neighborhood, Neighborhood
  end
end
