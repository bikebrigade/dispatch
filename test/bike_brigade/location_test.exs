defmodule BikeBrigade.LocationTest do
  use BikeBrigade.DataCase

  alias BikeBrigade.Geocoder.FakeGeocoder
  alias BikeBrigade.Location

  describe "Geolocation" do
    setup do
      location = fixture(:location)
      FakeGeocoder.inject_address("#{location.address} #{location.city}", location)

      %{location: location}
    end

    test "geolocate a location", %{location: location} do
      geocoded =
        %Location{}
        |> Location.changeset(%{address: location.address, city: location.city})
        |> Location.geocode_changeset()
        |> Ecto.Changeset.apply_changes()

      assert geocoded == location
    end

    test "only re-geocode when changing address", %{location: location} do
      FakeGeocoder.inject_address("#{location.address} #{location.city}", %{
        location
        | postal: "Fake Postal"
      })

      location =
        location
        |> Location.changeset(%{unit: "37"})
        |> Location.geocode_changeset()
        |> Ecto.Changeset.apply_changes()

      assert location.postal != "Fake Postal"

      location =
        location
        |> Location.changeset(%{unit: "   #{location.address}"})
        |> Location.geocode_changeset()
        |> Ecto.Changeset.apply_changes()

      assert location.postal != "Fake Postal"
    end

    test "keep unit and buzzer when geocoding", %{location: location} do
      geocoded =
        %Location{unit: "10", buzzer: "Q"}
        |> Location.changeset(%{address: location.address, city: location.city})
        |> Location.geocode_changeset()
        |> Ecto.Changeset.apply_changes()

      assert geocoded.unit == "10"
      assert geocoded.buzzer == "Q"
    end


    test "parse unit", %{location: location} do
      geocoded =
        %Location{}
        |> Location.changeset(%{address: "11-#{location.address}", city: location.city})
        |> Location.geocode_changeset()
        |> Ecto.Changeset.apply_changes()

      assert geocoded.unit == "11"
    end
  end
end
