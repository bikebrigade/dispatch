defmodule BikeBrigade.Locations.CommunityFridgeTest do
  use BikeBrigade.DataCase

  alias BikeBrigade.Locations.CommunityFridge

  setup do
    location_data = fixture(:location)

    {:ok, location} =
      %BikeBrigade.Locations.Location{}
      |> BikeBrigade.Locations.Location.changeset(location_data)
      |> Repo.insert()

    %{location: location}
  end

  describe "CommunityFridge changeset" do
    test "changeset with valid attributes", %{location: location} do
      attrs = %{
        name: "Downtown Community Fridge",
        description: "A fridge for the community",
        photo: "https://example.com/photo.jpg",
        active: true,
        pair_preferred: false,
        location_id: location.id
      }

      changeset = CommunityFridge.changeset(%CommunityFridge{}, attrs)

      assert changeset.valid?
    end

    test "changeset with minimal required attributes", %{location: location} do
      attrs = %{
        name: "Community Fridge",
        location_id: location.id
      }

      changeset = CommunityFridge.changeset(%CommunityFridge{}, attrs)

      assert changeset.valid?
    end

    test "changeset requires name", %{location: location} do
      attrs = %{
        description: "A fridge without a name",
        location_id: location.id
      }

      changeset = CommunityFridge.changeset(%CommunityFridge{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name
    end

    test "changeset rejects empty name", %{location: location} do
      attrs = %{
        name: "",
        location_id: location.id
      }

      changeset = CommunityFridge.changeset(%CommunityFridge{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name
    end

    test "changeset validates location_id is required" do
      attrs = %{
        name: "Fridge Without Location",
        description: "Missing location_id"
      }

      changeset = CommunityFridge.changeset(%CommunityFridge{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).location_id
    end

    test "changeset sets default values for active and pair_preferred", %{location: location} do
      attrs = %{
        name: "Fridge with Defaults",
        location_id: location.id
      }

      changeset = CommunityFridge.changeset(%CommunityFridge{}, attrs)

      assert Ecto.Changeset.get_field(changeset, :active) == true
      assert Ecto.Changeset.get_field(changeset, :pair_preferred) == false
    end
  end
end
