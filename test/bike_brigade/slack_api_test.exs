defmodule BikeBrigade.SlackApiTest do
  use BikeBrigade.DataCase

  alias BikeBrigade.SlackApi
  alias BikeBrigade.SlackApi.FakeSlack

  test "calls are posted to the configured webhook url as JSON" do
    :ok = SlackApi.send_webook("some message")

    call = FakeSlack.get_last_call()

    assert call.url == webhook_url()
    assert call.method == :post
    assert call.headers |> Enum.member?({"content-type", "application/json"})
  end

  defp webhook_url() do
    BikeBrigade.Utils.fetch_env!(:slack, :webhook_url)
  end
end
