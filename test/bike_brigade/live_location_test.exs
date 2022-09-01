defmodule BikeBrigade.LiveLocationTest do
  use ExUnit.Case, async: true
  import BikeBrigadeWeb.Components.LiveLocation, only: [lookup_location: 2, parse_postal_code: 1]
  import BikeBrigade.Geocoder
  import Ecto.Changeset

  describe "lookup_location/2" do
    setup do
      location = %BikeBrigade.Locations.Location{
        address: "542 Dovercourt Rd",
        unit: nil,
        buzzer: nil,
        postal: "M6H 2W6",
        city: "Toronto",
        province: "Ontario",
        country: "Canada"
      }

      %{location: location}
    end

    test "Changes address and postal with address and city", %{location: location} do
      value = "16 Millington St Toronto"

      assert %BikeBrigade.Locations.Location{
               address: "16 Millington St",
               unit: nil,
               buzzer: nil,
               postal: "M4X 1W8",
               city: "Toronto",
               province: "Ontario",
               country: "Canada"
             } = apply_changes(lookup_location(location, value))
    end

    test "Allows for just postal code", %{location: location} do
      value = "M4X 1W8"

      IO.inspect(lookup_location(location, value))
      IO.inspect(BikeBrigade.Geocoder.lookup(value))
      IO.inspect(BikeBrigade.Geocoder.lookup("1 Roof Garden Lane"))

      assert %BikeBrigade.Locations.Location{
               address: nil,
               unit: nil,
               buzzer: nil,
               postal: "M4X 1W8",
               city: "Toronto",
               province: "Ontario",
               country: "Canada"
             } = apply_changes(lookup_location(location, value))
    end

    test "Clears unit when does not have in value", %{location: location} do
      location = %{location | unit: "123"}

      value = "542 Dovercourt Rd"

      assert %BikeBrigade.Locations.Location{
               address: "542 Dovercourt Rd",
               unit: nil,
               buzzer: nil,
               postal: "M6H 2W6",
               city: "Toronto",
               province: "Ontario",
               country: "Canada"
             } = apply_changes(lookup_location(location, value))
    end

    test "Clears buzzer when does not have in value", %{location: location} do
      location = %{location | buzzer: "Buzz 1234"}

      value = "542 Dovercourt Rd"

      assert %BikeBrigade.Locations.Location{
               address: "542 Dovercourt Rd",
               unit: nil,
               buzzer: nil,
               postal: "M6H 2W6",
               city: "Toronto",
               province: "Ontario",
               country: "Canada"
             } = apply_changes(lookup_location(location, value))
    end

    @tag :skip
    test "Changes unit as specified", %{location: location} do
      value = "542 Dovercourt Rd Unit 1"

      assert %BikeBrigade.Locations.Location{
               address: "542 Dovercourt Rd",
               unit: "1",
               buzzer: nil,
               postal: "M6H 2W6",
               city: "Toronto",
               province: "Ontario",
               country: "Canada"
             } = apply_changes(lookup_location(location, value))

      value = "1-542 Dovercourt Rd"

      assert %BikeBrigade.Locations.Location{
               address: "542 Dovercourt Rd",
               unit: "1",
               buzzer: nil,
               postal: "M6H 2W6",
               city: "Toronto",
               province: "Ontario",
               country: "Canada"
             } = apply_changes(lookup_location(location, value))
    end
  end

  test "parse_postal_code/2" do
    assert parse_postal_code("M4X 1W8") == "M4X 1W8"
    assert parse_postal_code("M4X1W8") == "M4X 1W8"
    assert parse_postal_code("m4x 1w8") == "M4X 1W8"
    assert parse_postal_code("m4x1w8") == "M4X 1W8"
    assert parse_postal_code("m4x 1w") == "m4x 1w"

    assert parse_postal_code("16 Millington St, Toronto, M4X 1W8") ==
             "16 Millington St, Toronto, M4X 1W8"

    assert parse_postal_code(" m4x 1w8, ") == "M4X 1W8"
    assert parse_postal_code(", M4X   1W8") == "M4X 1W8"
  end
end
