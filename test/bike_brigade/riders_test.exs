defmodule BikeBrigade.RidersTest do
  use BikeBrigade.DataCase

  alias BikeBrigade.Utils
  alias BikeBrigade.LocalizedDateTime
  alias BikeBrigade.Riders
  alias BikeBrigade.Riders.Rider

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
end
