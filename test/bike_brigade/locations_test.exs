defmodule BikeBrigade.LocationsTest do
  use BikeBrigade.DataCase

  alias BikeBrigade.Locations

  describe "community_fridges" do
    alias BikeBrigade.Locations.CommunityFridge

    import BikeBrigade.LocationsFixtures

    @invalid_attrs %{active: nil, name: nil, description: nil, photo: nil, pair_preferred: nil}

    test "list_community_fridges/0 returns all community_fridges" do
      community_fridge = community_fridge_fixture()
      assert Locations.list_community_fridges() == [community_fridge]
    end

    test "get_community_fridge!/1 returns the community_fridge with given id" do
      community_fridge = community_fridge_fixture()
      assert Locations.get_community_fridge!(community_fridge.id) == community_fridge
    end

    test "create_community_fridge/1 with valid data creates a community_fridge" do
      valid_attrs = %{
        active: true,
        name: "some name",
        description: "some description",
        photo: "some photo",
        pair_preferred: true
      }

      assert {:ok, %CommunityFridge{} = community_fridge} =
               Locations.create_community_fridge(valid_attrs)

      assert community_fridge.active == true
      assert community_fridge.name == "some name"
      assert community_fridge.description == "some description"
      assert community_fridge.photo == "some photo"
      assert community_fridge.pair_preferred == true
    end

    test "create_community_fridge/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Locations.create_community_fridge(@invalid_attrs)
    end

    test "update_community_fridge/2 with valid data updates the community_fridge" do
      community_fridge = community_fridge_fixture()

      update_attrs = %{
        active: false,
        name: "some updated name",
        description: "some updated description",
        photo: "some updated photo",
        pair_preferred: false
      }

      assert {:ok, %CommunityFridge{} = community_fridge} =
               Locations.update_community_fridge(community_fridge, update_attrs)

      assert community_fridge.active == false
      assert community_fridge.name == "some updated name"
      assert community_fridge.description == "some updated description"
      assert community_fridge.photo == "some updated photo"
      assert community_fridge.pair_preferred == false
    end

    test "update_community_fridge/2 with invalid data returns error changeset" do
      community_fridge = community_fridge_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Locations.update_community_fridge(community_fridge, @invalid_attrs)

      assert community_fridge == Locations.get_community_fridge!(community_fridge.id)
    end

    test "delete_community_fridge/1 deletes the community_fridge" do
      community_fridge = community_fridge_fixture()
      assert {:ok, %CommunityFridge{}} = Locations.delete_community_fridge(community_fridge)

      assert_raise Ecto.NoResultsError, fn ->
        Locations.get_community_fridge!(community_fridge.id)
      end
    end

    test "change_community_fridge/1 returns a community_fridge changeset" do
      community_fridge = community_fridge_fixture()
      assert %Ecto.Changeset{} = Locations.change_community_fridge(community_fridge)
    end
  end
end
