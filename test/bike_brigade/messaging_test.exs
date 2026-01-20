defmodule BikeBrigade.MessagingTest do
  use BikeBrigade.DataCase

  alias BikeBrigade.Messaging

  describe "maybe_append_signature/2" do
    test "returns body unchanged when sent_by_user_id is nil" do
      assert Messaging.maybe_append_signature("Hello", nil) == "Hello"
    end

    test "returns body unchanged when user has signature_on_messages disabled" do
      user = fixture(:user, %{signature_on_messages: false, name: "Chad Smith"})
      assert Messaging.maybe_append_signature("Hello", user.id) == "Hello"
    end

    test "appends signature when user has signature_on_messages enabled" do
      user = fixture(:user, %{signature_on_messages: true, name: "Chad Smith"})
      result = Messaging.maybe_append_signature("Hello", user.id)
      assert result == "Hello\n\n(sent by: Chad)"
    end

    test "uses first name only" do
      user = fixture(:user, %{signature_on_messages: true, name: "Jane Doe"})
      result = Messaging.maybe_append_signature("Test message", user.id)
      assert result == "Test message\n\n(sent by: Jane)"
    end

    test "handles single-word names" do
      user = fixture(:user, %{signature_on_messages: true, name: "Prince"})
      result = Messaging.maybe_append_signature("Test", user.id)
      assert result == "Test\n\n(sent by: Prince)"
    end

    test "returns body unchanged when user does not exist" do
      assert Messaging.maybe_append_signature("Hello", 999_999) == "Hello"
    end

    test "returns body unchanged for non-integer sent_by_user_id" do
      assert Messaging.maybe_append_signature("Hello", "not_an_id") == "Hello"
    end
  end
end
