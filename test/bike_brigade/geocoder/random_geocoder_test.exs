defmodule BikeBrigade.Geocoder.RandomGeocoderTest do
  use BikeBrigade.DataCase, async: true

  alias BikeBrigade.Geocoder
  alias BikeBrigade.Geocoder.RandomGeocoder

  test "returns a random location in Toronto" do
    {:ok, %{city: city}} =
      Geocoder.lookup("1 Blue Jays Way",
        module: RandomGeocoder
      )

    assert city == "Toronto"
  end
end
