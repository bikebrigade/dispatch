defmodule BikeBrigade.Geocoder.FakeGeocoderTest do
  use BikeBrigade.DataCase, async: true

  alias BikeBrigade.Geocoder
  alias BikeBrigade.Geocoder.FakeGeocoder

  @address "1 Blue Jays Way Toronto"

  test "Fake geocoder" do
    location = fixture(:location)
    {:ok, pid} = FakeGeocoder.start_link(name: nil)
    FakeGeocoder.inject_address(pid, @address, location)

    {:ok, ^location} = FakeGeocoder.lookup(pid, @address)
  end

  test "Can lookup through the Geocoder interface" do
    location = fixture(:location)
    {:ok, pid} = FakeGeocoder.start_link(name: nil)
    FakeGeocoder.inject_address(pid, @address, location)

    {:ok, ^location} = Geocoder.lookup(@address, module: FakeGeocoder, pid: pid)
  end

  test "Fake is the default Geocoder in tests" do
    location = fixture(:location)
    FakeGeocoder.inject_address(@address, location)

    {:ok, ^location} = FakeGeocoder.lookup(@address)
    {:ok, ^location} = Geocoder.lookup(@address)
  end

  test "Can load locations from seeds" do
    {:ok, pid} = FakeGeocoder.start_link(name: nil, locations: :from_seeds)

    {:ok, location} = FakeGeocoder.lookup(pid, "542 Dovercourt Rd Toronto")
    assert location.postal == "M6H 2W6"
  end
end
