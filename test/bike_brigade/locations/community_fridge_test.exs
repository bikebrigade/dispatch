defmodule BikeBrigade.Locations.CommunityFridgeTest do
  use BikeBrigade.DataCase

  alias BikeBrigade.Locations.Location
  alias BikeBrigade.Locations.CommunityFridge

  setup do
    location_data = fixture(:location)

    {:ok, location} =
      %Location{}
      |> Location.changeset(location_data)
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

    test "changeset with minimal required attributes and default values", %{location: location} do
      attrs = %{
        name: "Community Fridge",
        location_id: location.id
      }

      changeset = CommunityFridge.changeset(%CommunityFridge{}, attrs)

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :active) == true
      assert Ecto.Changeset.get_field(changeset, :pair_preferred) == false
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
  end
end
