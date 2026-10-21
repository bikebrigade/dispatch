defmodule BikeBrigade.MessagingTest do
  use BikeBrigade.DataCase

  alias BikeBrigade.Messaging

  describe "maybe_append_signature/2" do
    test "returns body unchanged when sent_by_user_id is nil" do
      assert Messaging.maybe_append_signature("Hello", nil) == "Hello"
    end

    test "returns body unchanged when user has no signature set" do
      user = fixture(:user, %{signature_on_messages: nil, name: "Chad Smith"})
      assert Messaging.maybe_append_signature("Hello", user.id) == "Hello"
    end

    test "returns body unchanged when user has empty signature" do
      user = fixture(:user, %{signature_on_messages: "", name: "Chad Smith"})
      assert Messaging.maybe_append_signature("Hello", user.id) == "Hello"
    end

    test "appends signature when user has signature_on_messages set" do
      user = fixture(:user, %{signature_on_messages: "Chad", name: "Chad Smith"})
      result = Messaging.maybe_append_signature("Hello", user.id)
      assert result == "Hello\n\n(sent by: Chad)"
    end

    test "uses custom signature text" do
      user = fixture(:user, %{signature_on_messages: "Jane S", name: "Jane Doe"})
      result = Messaging.maybe_append_signature("Test message", user.id)
      assert result == "Test message\n\n(sent by: Jane S)"
    end

    test "returns body unchanged when user does not exist" do
      assert Messaging.maybe_append_signature("Hello", 999_999) == "Hello"
    end

    test "returns body unchanged for non-integer sent_by_user_id" do
      assert Messaging.maybe_append_signature("Hello", "not_an_id") == "Hello"
    end
  end

  describe "bulk message groups" do
    test "create_bulk_message_group/3 saves the creator and riders and broadcasts" do
      creator = fixture(:user, %{is_dispatcher: true})
      riders = [fixture(:rider), fixture(:rider)]
      Messaging.subscribe()

      assert {:ok, group} =
               Messaging.create_bulk_message_group(creator, riders, %{
                 name: "Backup riders",
                 body: "Anyone free?"
               })

      assert_receive {:bulk_message_group_created, %{id: id}}
      assert id == group.id

      assert [listed] = Messaging.list_bulk_message_groups()
      assert listed.creator.id == creator.id
      assert Enum.sort(Enum.map(listed.riders, & &1.id)) == Enum.sort(Enum.map(riders, & &1.id))
    end

    test "create_bulk_message_group/3 requires a name" do
      creator = fixture(:user, %{is_dispatcher: true})
      Messaging.subscribe()

      assert {:error, %Ecto.Changeset{}} =
               Messaging.create_bulk_message_group(creator, [fixture(:rider)], %{body: "Hi"})

      refute_receive {:bulk_message_group_created, _}
      assert Messaging.list_bulk_message_groups() == []
    end
  end

  describe "send_bulk_message/3" do
    defmodule SelectiveFailureSmsService do
      alias BikeBrigade.SmsService

      @behaviour SmsService

      @impl SmsService
      def send_sms(payload) do
        if payload[:to] == Application.get_env(:bike_brigade, :sms_service)[:test_failed_phone] do
          {:error, "Test transport failure"}
        else
          {:ok, %{status: "queued", sid: "TEST#{Ecto.UUID.generate()}"}}
        end
      end

      @impl SmsService
      def request_valid?(_url, _params, _signature), do: true
    end

    setup do
      cfg = Application.get_env(:bike_brigade, :sms_service)
      on_exit(fn -> Application.put_env(:bike_brigade, :sms_service, cfg) end)

      %{sender: fixture(:user, %{is_dispatcher: true})}
    end

    test "returns a changeset describing what's missing", %{sender: sender} do
      rider = fixture(:rider)

      assert {:error, changeset} = Messaging.send_bulk_message(sender, %{body: "Hi"})
      assert %{rider_ids: ["Select at least one rider"]} = errors_on(changeset)

      assert {:error, changeset} =
               Messaging.send_bulk_message(sender, %{rider_ids: [rider.id], body: "  "})

      assert %{body: ["Enter a message"]} = errors_on(changeset)

      assert {:error, changeset} =
               Messaging.send_bulk_message(sender, %{
                 rider_ids: [rider.id],
                 body: String.duplicate("a", 1601)
               })

      assert %{body: ["Messages can be up to 1600 characters"]} = errors_on(changeset)

      assert {:error, changeset} =
               Messaging.send_bulk_message(sender, %{
                 rider_ids: [rider.id],
                 body: "Hi",
                 save_group: true
               })

      assert %{group_name: ["Enter a name for the group"]} = errors_on(changeset)
      assert Messaging.latest_messages(rider) == []
    end

    test "the body is optional when there are attachments" do
      assert Messaging.change_bulk_message(%{rider_ids: [1]}, has_media: true).valid?
      refute Messaging.change_bulk_message(%{rider_ids: [1]}).valid?
    end

    test "partial transport failures keep the saved group and report failed riders", %{
      sender: sender
    } do
      successful = fixture(:rider, %{flags: %{initial_message_sent: true}})
      failed = fixture(:rider)
      BikeBrigade.Utils.put_env(:sms_service, :adapter, SelectiveFailureSmsService)
      BikeBrigade.Utils.put_env(:sms_service, :test_failed_phone, failed.phone)

      assert {:ok, result} =
               Messaging.send_bulk_message(sender, %{
                 rider_ids: [successful.id, failed.id],
                 body: "Test message",
                 save_group: true,
                 group_name: "Retry cohort"
               })

      assert result.sent == 1
      assert Enum.map(result.failed, & &1.id) == [failed.id]
      assert length(result.group.riders) == 2
      assert Enum.any?(Messaging.latest_messages(successful), &(&1.body =~ "Test message"))
      assert Messaging.latest_messages(failed) == []
    end
  end
end
