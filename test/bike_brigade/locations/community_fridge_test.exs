defmodule BikeBrigade.Locations.CommunityFridgeTest do
  use BikeBrigade.DataCase

  alias BikeBrigade.Locations
  alias BikeBrigade.Locations.CommunityFridge
  alias BikeBrigade.Repo.Seeds.Toronto

  describe "CommunityFridge changeset" do
    test "valid with nested location params" do
      attrs = %{
        name: "Downtown Community Fridge",
        description: "A fridge for the community",
        active: true,
        pair_preferred: false,
        location: Toronto.random_location()
      }

      changeset = CommunityFridge.changeset(%CommunityFridge{location: nil}, attrs)

      assert changeset.valid?
    end

    test "valid without a location" do
      changeset =
        CommunityFridge.changeset(%CommunityFridge{location: nil}, %{name: "Bare Fridge"})

      assert changeset.valid?
    end

    test "requires name" do
      changeset =
        CommunityFridge.changeset(%CommunityFridge{location: nil}, %{
          location: Toronto.random_location()
        })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name
    end

    test "rejects empty name" do
      changeset =
        CommunityFridge.changeset(%CommunityFridge{location: nil}, %{
          name: "",
          location: Toronto.random_location()
        })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name
    end

    test "updating location updates the associated record in place" do
      fridge = fixture(:community_fridge)
      original_location_id = fridge.location.id

      new_location = Toronto.random_location()
      {:ok, updated} = Locations.update_community_fridge(fridge, %{location: new_location})

      assert updated.location.id == original_location_id
      assert updated.location.address == new_location.address
    end
  end
end
