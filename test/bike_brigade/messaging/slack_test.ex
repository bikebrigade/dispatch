defmodule BikeBrigade.Messaging.SlackTest do
  use BikeBrigade.DataCase, async: true

  alias BikeBrigade.SlackApi.FakeSlack
  alias BikeBrigade.Messaging.Slack.RiderSms
  alias BikeBrigade.Messaging.Slack.Operations

  describe "RiderSms" do
    test "post_message posts expected payload to Slack" do
      assert :ok == RiderSms.post_message("hello")

      call = FakeSlack.get_last_call()
      payload = body(call)
      assert payload["channel"] == "C022R3HU9B9"
    end
  end

  describe "Operations" do
    test "post_message posts expected payload to Slack" do
      assert :ok == Operations.post_message("hello")

      call = FakeSlack.get_last_call()
      payload = body(call)
      assert payload["channel"] == "C022R3HU9B9"
    end
  end

  def body(call) do
    Jason.decode!(call.body)
  end
end
