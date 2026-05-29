defmodule BikeBrigade.LocationsTest do
  use BikeBrigade.DataCase

  alias BikeBrigade.Locations
  alias BikeBrigade.Locations.CommunityFridge

  describe "list_community_fridges/1" do
    setup do
      # Create community fridges with different attributes
      fridge1 = fixture(:community_fridge, %{name: "North End Fridge", active: true})
      fridge2 = fixture(:community_fridge, %{name: "South Side Fridge", active: true})
      fridge3 = fixture(:community_fridge, %{name: "East Community Fridge", active: false})
      fridge4 = fixture(:community_fridge, %{name: "West Valley Fridge", active: true})

      %{
        active_fridges: [fridge1, fridge2, fridge4],
        inactive_fridge: fridge3,
        all_fridges: [fridge1, fridge2, fridge3, fridge4]
      }
    end

    test "returns all fridges ordered by active status and name" do
      fridges = Locations.list_community_fridges()

      assert length(fridges) == 4

      # Verify ordering: active first (desc), then by name (asc)
      [first, second, third, fourth] = fridges

      # All active fridges should come before inactive ones
      assert first.active == true
      assert second.active == true
      assert third.active == true
      assert fourth.active == false

      # Active fridges should be ordered alphabetically by name
      assert first.name == "North End Fridge"
      assert second.name == "South Side Fridge"
      assert third.name == "West Valley Fridge"

      # Inactive fridges follow
      assert fourth.name == "East Community Fridge"
    end

    test "preloads location by default" do
      fridges = Locations.list_community_fridges()
      fridge = hd(fridges)

      # Location should be preloaded
      assert %Ecto.Association.NotLoaded{} != fridge.location
      assert fridge.location.id != nil
    end

    test "respects custom preload option" do
      # Request no preload
      fridges = Locations.list_community_fridges(preload: [])
      fridge = hd(fridges)

      # Location should not be preloaded
      assert %Ecto.Association.NotLoaded{} = fridge.location
    end

    test "filters by search term (case insensitive)" do
      fridges = Locations.list_community_fridges(search: "north")

      assert length(fridges) == 1
      assert hd(fridges).name == "North End Fridge"
    end

    test "search matches partial names (case insensitive)" do
      fridges = Locations.list_community_fridges(search: "FRIDGE")

      # All fridges have "Fridge" in the name
      assert length(fridges) == 4
    end

    test "search returns empty list when no matches" do
      fridges = Locations.list_community_fridges(search: "nonexistent")

      assert fridges == []
    end

    test "search maintains ordering by active status and name" do
      # Search for "Side" which should match both "South Side" and "East"
      fridges = Locations.list_community_fridges(search: "Side")

      assert length(fridges) == 1
      assert hd(fridges).name == "South Side Fridge"
      assert hd(fridges).active == true
    end

    test "search with empty string returns all fridges" do
      fridges = Locations.list_community_fridges(search: "")

      assert length(fridges) == 4
    end

    test "returns empty list when no fridges exist" do
      # Delete all fridges
      Repo.delete_all(CommunityFridge)

      fridges = Locations.list_community_fridges()

      assert fridges == []
    end

    test "combines search and preload options" do
      fridges = Locations.list_community_fridges(search: "North", preload: [:location])

      assert length(fridges) == 1
      fridge = hd(fridges)
      assert fridge.name == "North End Fridge"
      assert %Ecto.Association.NotLoaded{} != fridge.location
    end
  end

  describe "get_community_fridge!/2" do
    setup do
      fridge = fixture(:community_fridge, %{name: "Test Fridge"})
      %{fridge: fridge}
    end

    test "returns the fridge with given id", %{fridge: fridge} do
      found_fridge = Locations.get_community_fridge!(fridge.id)

      assert found_fridge.id == fridge.id
      assert found_fridge.name == "Test Fridge"
    end

    test "raises error when fridge does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Locations.get_community_fridge!(999_999)
      end
    end

    test "does not preload associations by default", %{fridge: fridge} do
      found_fridge = Locations.get_community_fridge!(fridge.id)

      assert %Ecto.Association.NotLoaded{} = found_fridge.location
    end

    test "preloads associations when specified", %{fridge: fridge} do
      found_fridge = Locations.get_community_fridge!(fridge.id, preload: [:location])

      assert %Ecto.Association.NotLoaded{} != found_fridge.location
      assert found_fridge.location.id != nil
    end
  end

  describe "get_community_fridge_by_name/2" do
    setup do
      fridge = fixture(:community_fridge, %{name: "Unique Fridge Name"})
      %{fridge: fridge}
    end

    test "returns the fridge with given name", %{fridge: fridge} do
      found_fridge = Locations.get_community_fridge_by_name("Unique Fridge Name")

      assert found_fridge.id == fridge.id
      assert found_fridge.name == "Unique Fridge Name"
    end

    test "returns nil when fridge does not exist" do
      assert Locations.get_community_fridge_by_name("Nonexistent Fridge") == nil
    end

    test "does not preload associations by default", %{fridge: _fridge} do
      found_fridge = Locations.get_community_fridge_by_name("Unique Fridge Name")

      assert %Ecto.Association.NotLoaded{} = found_fridge.location
    end

    test "preloads associations when specified", %{fridge: _fridge} do
      found_fridge =
        Locations.get_community_fridge_by_name("Unique Fridge Name", preload: [:location])

      assert %Ecto.Association.NotLoaded{} != found_fridge.location
      assert found_fridge.location.id != nil
    end
  end

  describe "create_community_fridge/1" do
    test "creates a fridge with valid attributes" do
      location = fixture(:location)

      {:ok, location_record} =
        %BikeBrigade.Locations.Location{}
        |> BikeBrigade.Locations.Location.changeset(location)
        |> Repo.insert()

      attrs = %{
        name: "New Community Fridge",
        description: "A brand new fridge",
        active: true,
        pair_preferred: false,
        location_id: location_record.id
      }

      assert {:ok, %CommunityFridge{} = fridge} = Locations.create_community_fridge(attrs)
      assert fridge.name == "New Community Fridge"
      assert fridge.description == "A brand new fridge"
      assert fridge.active == true
      assert fridge.pair_preferred == false
      assert fridge.location_id == location_record.id
    end

    test "returns error changeset when name is missing" do
      location = fixture(:location)

      {:ok, location_record} =
        %BikeBrigade.Locations.Location{}
        |> BikeBrigade.Locations.Location.changeset(location)
        |> Repo.insert()

      attrs = %{
        description: "A fridge without a name",
        location_id: location_record.id
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Locations.create_community_fridge(attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error changeset when location_id is missing" do
      attrs = %{
        name: "Fridge without location"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Locations.create_community_fridge(attrs)
      assert %{location_id: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error changeset when location_id is invalid" do
      attrs = %{
        name: "Fridge with invalid location",
        location_id: 999_999
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Locations.create_community_fridge(attrs)
      assert %{location: ["does not exist"]} = errors_on(changeset)
    end

    test "sets default values for active and pair_preferred" do
      location = fixture(:location)

      {:ok, location_record} =
        %BikeBrigade.Locations.Location{}
        |> BikeBrigade.Locations.Location.changeset(location)
        |> Repo.insert()

      attrs = %{
        name: "Fridge with defaults",
        location_id: location_record.id
      }

      assert {:ok, %CommunityFridge{} = fridge} = Locations.create_community_fridge(attrs)
      assert fridge.active == true
      assert fridge.pair_preferred == false
    end
  end

  describe "update_community_fridge/2" do
    setup do
      fridge = fixture(:community_fridge, %{name: "Original Name", active: true})
      %{fridge: fridge}
    end

    test "updates the fridge with valid attributes", %{fridge: fridge} do
      update_attrs = %{
        name: "Updated Name",
        description: "Updated description",
        active: false,
        pair_preferred: true
      }

      assert {:ok, %CommunityFridge{} = updated_fridge} =
               Locations.update_community_fridge(fridge, update_attrs)

      assert updated_fridge.id == fridge.id
      assert updated_fridge.name == "Updated Name"
      assert updated_fridge.description == "Updated description"
      assert updated_fridge.active == false
      assert updated_fridge.pair_preferred == true
    end

    test "returns error changeset when name is blank", %{fridge: fridge} do
      update_attrs = %{name: ""}

      assert {:error, %Ecto.Changeset{} = changeset} =
               Locations.update_community_fridge(fridge, update_attrs)

      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error changeset when location_id is invalid", %{fridge: fridge} do
      update_attrs = %{location_id: 999_999}

      assert {:error, %Ecto.Changeset{} = changeset} =
               Locations.update_community_fridge(fridge, update_attrs)

      assert %{location: ["does not exist"]} = errors_on(changeset)
    end

    test "updates only specified fields", %{fridge: fridge} do
      update_attrs = %{description: "Only description updated"}

      assert {:ok, %CommunityFridge{} = updated_fridge} =
               Locations.update_community_fridge(fridge, update_attrs)

      assert updated_fridge.name == fridge.name
      assert updated_fridge.description == "Only description updated"
      assert updated_fridge.active == fridge.active
    end
  end

  describe "delete_community_fridge/1" do
    setup do
      fridge = fixture(:community_fridge, %{name: "Fridge to Delete"})
      %{fridge: fridge}
    end

    test "deletes the fridge", %{fridge: fridge} do
      assert {:ok, %CommunityFridge{}} = Locations.delete_community_fridge(fridge)

      assert_raise Ecto.NoResultsError, fn ->
        Locations.get_community_fridge!(fridge.id)
      end
    end

    test "returns the deleted fridge", %{fridge: fridge} do
      assert {:ok, deleted_fridge} = Locations.delete_community_fridge(fridge)
      assert deleted_fridge.id == fridge.id
      assert deleted_fridge.name == "Fridge to Delete"
    end
  end
end
