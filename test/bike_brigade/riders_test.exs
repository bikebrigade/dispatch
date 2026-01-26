defmodule BikeBrigade.RidersTest do
  use BikeBrigade.DataCase

  alias BikeBrigade.Utils
  alias BikeBrigade.LocalizedDateTime
  alias BikeBrigade.Riders
  alias BikeBrigade.Riders.{Rider, Tag}

  alias BikeBrigade.Accounts
  alias BikeBrigade.Accounts.User
  alias BikeBrigade.Locations.Location
  alias BikeBrigade.Messaging.SmsMessage

  describe "creating riders" do
    test "creates a rider with a user" do
      location = BikeBrigade.Repo.Seeds.Toronto.random_location()

      assert {:ok, rider} =
               Riders.create_rider_with_user(%{
                 address: location.address,
                 capacity: Utils.random_enum(Riders.Rider.CapacityEnum),
                 email: Faker.Internet.email(),
                 location: location,
                 max_distance: 20,
                 name: "Test Rider",
                 phone: "+16474567890",
                 postal: location.postal,
                 pronouns: Enum.random(~w(He/Him She/Her They/Them)),
                 signed_up_on: LocalizedDateTime.now()
               })

      assert rider.name == "Test Rider"
      assert rider.phone == "+16474567890"

      user = Accounts.get_user_by_phone("+16474567890")
      assert user.rider_id == rider.id
    end
  end

  describe "removing riders" do
    setup do
      rider = fixture(:rider)

      %{rider: rider}
    end

    test "marks rider as removed", %{rider: rider} do
      assert is_nil(rider.deleted_at)
      assert {:ok, %Rider{}} = Riders.remove_rider(rider)

      rider = Riders.get_rider(rider.id, include_deleted: true)

      refute is_nil(rider.deleted_at)
    end

    test "removes riders's PII", %{rider: %{location_id: location_id} = rider} do
      assert {:ok, rider} = Riders.remove_rider(rider)
      assert rider.name == "Deleted Rider"
      assert is_nil(rider.phone)
      assert is_nil(rider.email)
      assert is_nil(rider.pronouns)
      assert is_nil(rider.location_id)

      # Make sure location is actually deleted
      assert is_nil(Repo.get(Location, location_id))
    end

    test "can add and remove tags", %{rider: rider} do
      assert Ecto.assoc_loaded?(rider.tags) == false
      rider = rider |> Repo.preload(:tags)
      assert rider.tags == []

      {:ok, rider} = rider |> Riders.update_rider_with_tags(%{}, ["tag1", "tag2"])
      assert Enum.count(rider.tags) == 2

      {:ok, rider} = rider |> Riders.update_rider_with_tags(%{}, [])
      assert Enum.count(rider.tags) == 0
    end

    test "deletes associated tags", %{rider: rider} do
      rider
      |> Repo.preload(:tags)
      |> Riders.update_rider_with_tags(%{}, ["tag1", "tag2"])

      assert {:ok, rider} = Riders.remove_rider(rider)

      rider = Riders.get_rider(rider.id, preload: [:tags])
      assert rider.tags == []
    end

    test "deletes associated user", %{rider: rider} do
      {:ok, user} = Accounts.create_user_for_rider(rider)

      assert {:ok, _rider} = Riders.remove_rider(rider)

      assert is_nil(Repo.get(User, user.id))
    end

    test "deletes any SMS conversations", %{rider: rider} do
      sms1 = fixture(:sms_message_from_rider, rider)
      sms2 = fixture(:sms_message_to_rider, rider)

      assert {:ok, _rider} = Riders.remove_rider(rider)

      assert is_nil(Repo.get(SmsMessage, sms1.id))
      assert is_nil(Repo.get(SmsMessage, sms2.id))
    end
  end

  describe "tags" do
    test "create_tag/1 creates a tag" do
      assert {:ok, tag} = Riders.create_tag(%{name: "Test Tag"})
      assert tag.name == "Test Tag"
      assert tag.restricted == false
    end

    test "create_tag/1 creates a restricted tag" do
      assert {:ok, tag} = Riders.create_tag(%{name: "Restricted Tag", restricted: true})
      assert tag.name == "Restricted Tag"
      assert tag.restricted == true
    end

    test "create_tag/1 validates name is required" do
      assert {:error, changeset} = Riders.create_tag(%{name: ""})
      assert "can't be blank" in errors_on(changeset).name
    end

    test "update_tag/2 updates a tag" do
      tag = fixture(:tag)
      assert {:ok, updated} = Riders.update_tag(tag, %{name: "Updated Name"})
      assert updated.name == "Updated Name"
    end

    test "delete_tag/1 deletes a tag" do
      tag = fixture(:tag)
      assert {:ok, _} = Riders.delete_tag(tag)
      assert is_nil(Repo.get(Tag, tag.id))
    end

    test "list_tags/0 returns all tags ordered by name" do
      _tag_c = fixture(:tag, %{name: "Charlie"})
      _tag_a = fixture(:tag, %{name: "Alpha"})
      _tag_b = fixture(:tag, %{name: "Bravo"})

      tags = Riders.list_tags()
      assert Enum.map(tags, & &1.name) == ["Alpha", "Bravo", "Charlie"]
    end

    test "list_tags_with_rider_count/0 returns tags with rider counts" do
      tag1 = fixture(:tag, %{name: "Tag With Riders"})
      _tag2 = fixture(:tag, %{name: "Tag Without Riders"})

      rider = fixture(:rider) |> Repo.preload(:tags)
      {:ok, _} = Riders.update_rider_with_tags(rider, %{}, [tag1.name])

      tags = Riders.list_tags_with_rider_count()

      tag1_result = Enum.find(tags, &(&1.name == "Tag With Riders"))
      tag2_result = Enum.find(tags, &(&1.name == "Tag Without Riders"))

      assert tag1_result.rider_count == 1
      assert tag2_result.rider_count == 0
    end

    test "toggle_tag_restricted/1 flips restricted status" do
      tag = fixture(:tag, %{restricted: false})
      assert tag.restricted == false

      {:ok, tag} = Riders.toggle_tag_restricted(tag)
      assert tag.restricted == true

      {:ok, tag} = Riders.toggle_tag_restricted(tag)
      assert tag.restricted == false
    end

    test "change_tag/2 returns a changeset" do
      tag = fixture(:tag)
      changeset = Riders.change_tag(tag, %{name: "New Name"})
      assert %Ecto.Changeset{} = changeset
    end

    test "get_tag!/1 returns a tag" do
      tag = fixture(:tag)
      assert Riders.get_tag!(tag.id).id == tag.id
    end

    test "search_tags/2 searches tags by name" do
      fixture(:tag, %{name: "Delivery"})
      fixture(:tag, %{name: "Express Delivery"})
      fixture(:tag, %{name: "Pickup"})

      results = Riders.search_tags("deliv")
      assert length(results) == 2
      assert Enum.all?(results, &String.contains?(String.downcase(&1.name), "deliv"))
    end
  end
end
