defmodule BikeBrigade.UtilsTest do
  use ExUnit.Case, async: true
  import BikeBrigadeWeb.Components.LiveLocation, only: [lookup_location: 2]
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

    @tag :skip
    test "Allows for just postal code", %{location: location} do
      value = "M4X 1W8"

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

    @tag :skip
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

    @tag :skip
    test "Clears buzzzer when does not have in value", %{location: location} do
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
  end
end
