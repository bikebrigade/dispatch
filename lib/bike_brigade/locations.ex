defmodule BikeBrigade.Locations do
  alias BikeBrigade.Repo
  alias BikeBrigade.Locations.Location

  def neighborhood(%Location{} = location) do
    if neighborhood = Repo.preload(location, :neighborhood).neighborhood do
      neighborhood.name
    else
      "Unknown"
    end
  end

  def neighborhood(nil) do
    "Unknown"
  end
end
