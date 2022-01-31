defmodule BikeBrigade.SlackApiTest do
  use BikeBrigade.DataCase

  alias BikeBrigade.SlackApi
  alias BikeBrigade.SlackApi.FakeSlack

  test "calls include the expected headers" do
    :ok = SlackApi.post_message!("some message")

    call = FakeSlack.get_last_call()

    assert call.method == :post
    assert call.headers
      |> Enum.member?({"content-type", "application/json"})
    assert call.headers
      |> Enum.member?({"charset", "utf-8"})
    assert call.headers
      |> Enum.member?({"authorization", "Bearer #{token()}"})
  end

  defp token() do
    BikeBrigade.Utils.fetch_env!(:slack, :token)
  end
end
