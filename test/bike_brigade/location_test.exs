defmodule BikeBrigade.Locations.LocationTest do
  use BikeBrigade.DataCase

  alias BikeBrigade.Geocoder.FakeGeocoder
  alias BikeBrigade.Locations.Location

  describe "Geolocation" do
    setup do
      location = fixture(:location)
      FakeGeocoder.inject_address("#{location.address} #{location.city}", location)

      %{location: location}
    end

    test "geolocate a location", %{location: location} do
      geocoded =
        %Location{}
        |> Location.geocoding_changeset(%{address: location.address, city: location.city})
        |> Ecto.Changeset.apply_changes()

      assert geocoded.coords == location.coords
    end

    test "only re-geocode when changing address", %{location: location} do
      FakeGeocoder.inject_address("#{location.address} #{location.city}", %{
        location
        | postal: "Fake Postal"
      })

      location =
        %Location{}
        |> Location.changeset(location)
        |> Ecto.Changeset.apply_changes()
        |> Location.geocoding_changeset(%{unit: "37"})
        |> Ecto.Changeset.apply_changes()

      assert location.postal != "Fake Postal"

      location =
        location
        |> Location.geocoding_changeset(%{unit: "   #{location.address}"})
        |> Ecto.Changeset.apply_changes()

      assert location.postal != "Fake Postal"
    end

    test "keep unit and buzzer when geocoding", %{location: location} do
      geocoded =
        %Location{unit: "10", buzzer: "Q"}
        |> Location.geocoding_changeset(%{address: location.address, city: location.city})
        |> Ecto.Changeset.apply_changes()

      assert geocoded.unit == "10"
      assert geocoded.buzzer == "Q"
    end

    test "parse unit", %{location: location} do
      geocoded =
        %Location{}
        |> Location.geocoding_changeset(%{address: "11-#{location.address}", city: location.city})
        |> Ecto.Changeset.apply_changes()

      assert geocoded.unit == "11"
    end
  end

  test "String.Chats.to_string/1" do
    # 540 Manning Ave,M6G 2V9,Toronto,43.660616,-79.4149899

    location = %Location{
      country: "Canada",
      province: "Ontario",
      city: "Toronto",
      postal: "M6G 2V9"
    }

    assert "#{location}" == "M6G 2V9, Toronto"
    assert "#{%{location | address: "540 Manning Ave"}}" == "540 Manning Ave, M6G 2V9, Toronto"
    assert "#{%{location | address: "540 Manning Ave", unit: "123"}}" == "540 Manning Ave Unit 123, M6G 2V9, Toronto"
    assert "#{%{location | address: "540 Manning Ave", buzzer: "57"}}" == "540 Manning Ave (Buzz 57), M6G 2V9, Toronto"
    assert "#{%{location | address: "540 Manning Ave",  unit: "123", buzzer: "57"}}" == "540 Manning Ave Unit 123 (Buzz 57), M6G 2V9, Toronto"



  end
end
