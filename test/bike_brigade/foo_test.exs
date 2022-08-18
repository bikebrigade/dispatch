defmodule BikeBrigade.UtilsTest do
  use ExUnit.Case, async: true
  import BikeBrigadeWeb.Components.LiveLocation, only: [lookup_location: 2]
  import Ecto.Changeset

  test "Changes address and postal with address and city" do
    location = %BikeBrigade.Locations.Location{
      address: "542 Dovercourt Rd",
      unit: nil,
      buzzer: nil,
      postal: "M6H 2W6",
      city: "Toronto",
      province: "Ontario",
      country: "Canada"
    }

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
  test "Allows for just postal code" do
    location = %BikeBrigade.Locations.Location{
      address: "540 Manning Avenue",
      unit: "123",
      buzzer: nil,
      postal: "M6G 2V9",
      city: "Toronto",
      province: "Ontario",
      country: "Canada"
    }

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
  test "Clears unit when does not have in value" do
    location = %BikeBrigade.Locations.Location{
      address: "540 Manning Avenue",
      unit: "123",
      buzzer: nil,
      postal: "M6G 2V9",
      city: "Toronto",
      province: "Ontario",
      country: "Canada"
    }

    value = "540 Manning Avenue Toronto"

    assert %BikeBrigade.Locations.Location{
             address: "540 Manning Avenue",
             unit: nil,
             buzzer: nil,
             postal: "M6G 2V9",
             city: "Toronto",
             province: "Ontario",
             country: "Canada"
           } = apply_changes(lookup_location(location, value))
  end

  @tag :skip
  test "Clears buzzzer when does not have in value" do
    location = %BikeBrigade.Locations.Location{
      address: "540 Manning Avenue",
      unit: nil,
      buzzer: "1234",
      postal: "M6G 2V9",
      city: "Toronto",
      province: "Ontario",
      country: "Canada"
    }

    value = "540 Manning Avenue Toronto"

    assert %BikeBrigade.Locations.Location{
             address: "540 Manning Avenue",
             unit: nil,
             buzzer: nil,
             postal: "M6G 2V9",
             city: "Toronto",
             province: "Ontario",
             country: "Canada"
           } = apply_changes(lookup_location(location, value))
  end
end
