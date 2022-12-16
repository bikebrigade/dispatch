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

  describe "change_location/2" do
    setup do
      location = fixture(:location)
      FakeGeocoder.inject_address("#{location.address}", location)
      FakeGeocoder.inject_address("#{location.postal}", location)

      %{location: location}
    end

    test "change address", %{location: %{address: address, coords: coords} = location} do
      assert {:error, _} =
               Location.change_location(%Location{}, :address, "11414")
               |> Ecto.Changeset.apply_action(:update)

      assert {:ok, %{address: "", coords: %Geo.Point{}}} =
               Location.change_location(%Location{}, :address, "")
               |> Ecto.Changeset.apply_action(:update)

      assert {:ok, %{address: ^address, coords: ^coords}} =
               Location.change_location(%Location{}, :address, location.address)
               |> Ecto.Changeset.apply_action(:update)
    end

    test "change postal", %{location: %{postal: postal, coords: coords} = _location} do
      assert {:error, _} =
               Location.change_location(%Location{}, :postal, "m62aaaa")
               |> Ecto.Changeset.apply_action(:update)

      assert {:ok, %{postal: "m6a", coords: %Geo.Point{}}} =
               Location.change_location(%Location{}, :postal, "m6a")
               |> Ecto.Changeset.apply_action(:update)

      assert {:ok, %{postal: ^postal, coords: ^coords}} =
               Location.change_location(%Location{}, :postal, postal)
               |> Ecto.Changeset.apply_action(:update)
    end

    test "change using smart input", %{
      location: %{address: address, postal: postal, coords: coords} = _location
    } do
      assert {:error, _} =
               Location.change_location(%Location{}, :smart_input, "m62aaaa")
               |> Ecto.Changeset.apply_action(:update)

      assert {:error, _} =
               Location.change_location(%Location{}, :smart_input, "924 Fake street")
               |> Ecto.Changeset.apply_action(:update)

      assert {:ok, %{postal: "m6a", coords: %Geo.Point{}}} =
               Location.change_location(%Location{}, :smart_input, "m6a")
               |> Ecto.Changeset.apply_action(:update)

      assert {:ok, %{address: ^address, postal: ^postal, coords: ^coords}} =
               Location.change_location(%Location{}, :smart_input, address)
               |> Ecto.Changeset.apply_action(:update)

      assert {:ok, %{address: ^address, postal: ^postal, coords: ^coords}} =
               Location.change_location(%Location{}, :smart_input, postal)
               |> Ecto.Changeset.apply_action(:update)
    end
  end

  test "parse_postal_code/1" do
    assert Location.parse_postal_code("A") == {:error, :partial_postal}
    assert Location.parse_postal_code("A1") == {:error, :partial_postal}
    assert Location.parse_postal_code("A1a") == {:error, :partial_postal}
    assert Location.parse_postal_code("A1a2") == {:error, :partial_postal}
    assert Location.parse_postal_code("A1a 2") == {:error, :partial_postal}
    assert Location.parse_postal_code("A1a 2A") == {:error, :partial_postal}
    assert Location.parse_postal_code("A1a2A") == {:error, :partial_postal}
    assert Location.parse_postal_code("A1a2A1") == {:ok, "A1A 2A1"}
    assert Location.parse_postal_code("A1a 2A1") == {:ok, "A1A 2A1"}
    assert Location.parse_postal_code("A1a 2A12") == {:error, :invalid_postal}
    assert Location.parse_postal_code("Aa") == {:error, :invalid_postal}
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

    assert "#{%{location | address: "540 Manning Ave", unit: "123"}}" ==
             "540 Manning Ave Unit 123, M6G 2V9, Toronto"

    assert "#{%{location | address: "540 Manning Ave", buzzer: "57"}}" ==
             "540 Manning Ave (Buzz 57), M6G 2V9, Toronto"

    assert "#{%{location | address: "540 Manning Ave", unit: "123", buzzer: "57"}}" ==
             "540 Manning Ave Unit 123 (Buzz 57), M6G 2V9, Toronto"
  end
end
