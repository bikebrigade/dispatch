defmodule BikeBrigade.Messaging.SlackTest do
  use BikeBrigade.DataCase, async: true

  alias BikeBrigade.SlackApi.FakeSlack
  alias BikeBrigade.Messaging.Slack.RiderSms
  alias BikeBrigade.Messaging.Slack.Operations
  alias BikeBrigade.Messaging.Slack.DeliveryNotes

  describe "RiderSms" do
    test "post_message! posts expected payload to Slack" do
      assert :ok == RiderSms.post_message!("hello")

      call = FakeSlack.get_last_call()
      payload = body(call)
      assert payload["channel"] == "C022R3HU9B9"
    end
  end

  describe "Operations" do
    test "post_message! posts expected payload to Slack" do
      assert :ok == Operations.post_message!("hello")

      call = FakeSlack.get_last_call()
      payload = body(call)
      assert payload["channel"] == "C022R3HU9B9"
    end
  end

  describe "DeliveryNotes" do
    test "notify_note_created! posts to program's slack channel" do
      program = fixture(:program, %{slack_channel_id: "program_channel_123"})
      campaign = fixture(:campaign, %{program_id: program.id})
      rider = fixture(:rider)
      task = fixture(:task, %{campaign: campaign, rider: rider})
      delivery_note = fixture(:delivery_note, %{task: task, rider: rider})

      assert :ok == DeliveryNotes.notify_note_created!(delivery_note)

      call = FakeSlack.get_last_call()
      payload = body(call)
      assert payload["channel"] == "program_channel_123"
    end
  end

  def body(call) do
    Jason.decode!(call.body)
  end
end
