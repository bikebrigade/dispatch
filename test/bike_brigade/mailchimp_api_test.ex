defmodule BikeBrigade.MailchimpApiTest do
  use BikeBrigade.DataCase

  alias BikeBrigade.MailchimpApi
  alias BikeBrigade.MailchimpApi.FakeMailchimp

  @list_id "ABCDEF123"
  @members [%{id: "123"}, %{id: "347"}]

  setup do
    on_exit(fn -> FakeMailchimp.clear_members(@list_id) end)
  end

  test "`get_list(list_id)` returns list members" do
    assert MailchimpApi.get_list(@list_id) == {:ok, []}

    FakeMailchimp.add_members(@list_id, @members)

    assert MailchimpApi.get_list(@list_id) == {:ok, @members}
  end

  test "`get_list(list_id, last_changed)` returns members created since `last`changed" do
    now = DateTime.utc_now() |> DateTime.to_iso8601()

    ten_minutes_later =
      DateTime.utc_now()
      |> DateTime.add(60 * 60 * 10)
      |> DateTime.to_iso8601()

    FakeMailchimp.add_members(@list_id, @members)

    assert MailchimpApi.get_list(@list_id, now) == {:ok, @members}
    assert MailchimpApi.get_list(@list_id, ten_minutes_later) == {:ok, []}
  end
end
