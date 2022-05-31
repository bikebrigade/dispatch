defmodule BikeBrigade.MailchimpApiTest do
  use BikeBrigade.DataCase

  alias BikeBrigade.MailchimpApi
  alias BikeBrigade.MailchimpApi.FakeMailchimp

  @list_id "ABCDEF123"
  @members [%{email: "hello@example.com", id: "123"}, %{email: "googbye@example.com", id: "347"}]

  setup do
    on_exit(fn -> FakeMailchimp.clear_members(@list_id) end)
  end

  test "`get_list(list_id)` returns list members" do
    assert MailchimpApi.get_list(@list_id) == {:ok, []}

    FakeMailchimp.add_members(@list_id, @members)

    {:ok, members} = MailchimpApi.get_list(@list_id)
    assert Enum.count(members) == 2
  end

  test "`get_list(list_id, opted_in)` returns members created since `opted_in`" do
    now = DateTime.utc_now() |> DateTime.to_iso8601()

    ten_minutes_later =
      DateTime.utc_now()
      |> DateTime.add(60 * 60 * 10)
      |> DateTime.to_iso8601()

    FakeMailchimp.add_members(@list_id, @members)

    {:ok, members} = MailchimpApi.get_list(@list_id)
    assert Enum.count(members) == 2

    assert MailchimpApi.get_list(@list_id, ten_minutes_later) == {:ok, []}
  end

  test "`update_member_fields(email, merge_fields)` updates a given member with merge fields" do
    member = %{email: "hello@example.com", id: "123"}
    FakeMailchimp.add_members(@list_id, [member])

    FakeMailchimp.update_member_fields(@list_id, "hello@example.com", %{foo: "bar"})

    {:ok, [m]} = MailchimpApi.get_list(@list_id)
    assert m[:merge_fields] == %{foo: "bar"}

    FakeMailchimp.update_member_fields(@list_id, "hello@example.com", %{bar: "baz"})

    {:ok, [m]} = MailchimpApi.get_list(@list_id)
    assert m[:merge_fields] == %{foo: "bar", bar: "baz"}
  end
end
