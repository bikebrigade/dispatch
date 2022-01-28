defmodule BikeBrigade.Geocoder.RandomGeocoder do
  alias BikeBrigade.Repo.Seeds.Toronto

  def lookup(_module \\ __MODULE__, _address) do
    location = Toronto.random_location()
    {:ok, location}
  end
end
