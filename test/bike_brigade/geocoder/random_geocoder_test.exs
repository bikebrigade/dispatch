defmodule BikeBrigade.Geocoder.RandomGeocoderTest do
  use BikeBrigade.DataCase, async: true

  alias BikeBrigade.Geocoder
  alias BikeBrigade.Geocoder.RandomGeocoder
  alias BikeBrigade.Location

  test "returns a random location in Toronto" do
    {:ok, %Location{city: city}} =
      Geocoder.lookup("1 Blue Jays Way Toronto",
        module: RandomGeocoder
      )

    assert city == "Toronto"
  end
end
