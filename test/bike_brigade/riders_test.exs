defmodule BikeBrigade.AccountsTest do
  use BikeBrigade.DataCase

  alias BikeBrigade.Riders
  alias BikeBrigade.Riders.Rider

  alias BikeBrigade.Accounts
  alias BikeBrigade.Accounts.User
  alias BikeBrigade.Locations.Location
  alias BikeBrigade.Messaging.SmsMessage

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
