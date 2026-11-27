defmodule BikeBrigade.GeocoderTest do
  use BikeBrigade.DataCase

  alias BikeBrigade.Geocoder
  alias BikeBrigade.Geocoder.FakeGeocoder

  @address "1 Blue Jays Way"

  setup do
    locations = :sys.get_state(FakeGeocoder)

    on_exit(fn ->
      :sys.replace_state(FakeGeocoder, fn _ -> locations end)
    end)
  end

  test "looks up address by a configured Geocoder.Adapter" do
    location = fixture(:location)
    FakeGeocoder.inject_address(@address, location)

    {:ok, found_location} = Geocoder.lookup(@address)
    assert found_location == location
  end
end
