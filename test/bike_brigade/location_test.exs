defmodule BikeBrigade.LocationTest do
  use BikeBrigade.DataCase

  alias BikeBrigade.Geocoder.FakeGeocoder
  alias BikeBrigade.Location

  test "completes a location" do
    location = fixture(:location)

    FakeGeocoder.inject_address("#{location.address} #{location.city}", location)

    assert Location.complete(%Location{address: location.address, city: location.city}) == {:ok, location}
  end
end
