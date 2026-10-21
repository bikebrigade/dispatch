defmodule BikeBrigade.LocationsTest do
  use BikeBrigade.DataCase, async: true

  alias BikeBrigade.Locations
  alias BikeBrigade.Locations.CommunityFridge

  describe "community_fridges" do
    @invalid_attrs %{active: nil, name: nil, description: nil, photo: nil, pair_preferred: nil}

    setup do
      %{community_fridge: fixture(:community_fridge)}
    end

    test "list_community_fridges/0 returns all community_fridges", %{
      community_fridge: community_fridge
    } do
      assert community_fridge.id in Enum.map(Locations.list_community_fridges(), & &1.id)
    end

    test "get_community_fridge!/1 returns the community_fridge with given id", %{
      community_fridge: community_fridge
    } do
      assert Locations.get_community_fridge!(community_fridge.id) == community_fridge
    end

    test "create_community_fridge/1 with valid data creates a community_fridge" do
      location = fixture(:persisted_location, %{})

      %{
        active: active,
        name: name,
        description: description,
        photo: photo,
        pair_preferred: pair_preferred
      } =
        valid_attrs = %{
          active: true,
          name: "some name",
          description: "some description",
          photo: "some photo",
          pair_preferred: true,
          location_id: location.id
        }

      assert {:ok,
              %CommunityFridge{
                active: ^active,
                name: ^name,
                description: ^description,
                photo: ^photo,
                pair_preferred: ^pair_preferred
              }} = Locations.create_community_fridge(valid_attrs)
    end

    test "create_community_fridge/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Locations.create_community_fridge(@invalid_attrs)
    end

    test "update_community_fridge/2 with valid data updates the community_fridge", %{
      community_fridge: community_fridge
    } do
      %{
        active: active,
        name: name,
        description: description,
        photo: photo,
        pair_preferred: pair_preferred
      } =
        update_attrs = %{
          active: false,
          name: "some updated name",
          description: "some updated description",
          photo: "some updated photo",
          pair_preferred: false
        }

      assert {:ok,
              %CommunityFridge{
                active: ^active,
                name: ^name,
                description: ^description,
                photo: ^photo,
                pair_preferred: ^pair_preferred
              }} = Locations.update_community_fridge(community_fridge, update_attrs)
    end

    test "delete_community_fridge/1 deletes the community_fridge", %{
      community_fridge: community_fridge
    } do
      assert {:ok, %CommunityFridge{}} = Locations.delete_community_fridge(community_fridge)

      assert_raise Ecto.NoResultsError, fn ->
        Locations.get_community_fridge!(community_fridge.id)
      end
    end

    test "change_community_fridge/1 returns a community_fridge changeset", %{
      community_fridge: community_fridge
    } do
      assert %Ecto.Changeset{} = Locations.change_community_fridge(community_fridge)
    end
  end

  describe "community_fridges ordering" do
    test "list_community_fridges/0 returns active fridges first then alphabetically by name" do
      inactive = fixture(:community_fridge, %{name: "Alpha", active: false})
      active_b = fixture(:community_fridge, %{name: "Beta", active: true})
      active_a = fixture(:community_fridge, %{name: "Alpha", active: true})

      assert Enum.map(Locations.list_community_fridges(), & &1.id) == [
               active_a.id,
               active_b.id,
               inactive.id
             ]
    end
  end
end
