defmodule BikeBrigade.SlackApi.FakeSlackTest do
  use BikeBrigade.DataCase, async: true

  alias BikeBrigade.SlackApi.FakeSlack

  test "API calls are stored for later introspection" do
    {:ok, pid} = FakeSlack.start_link(name: nil)
    FakeSlack.post!("one", "wat", [], pid)
    FakeSlack.post!("two", "wat", [], pid)

    %{url: "two"} = FakeSlack.get_last_call(pid)
  end
end
