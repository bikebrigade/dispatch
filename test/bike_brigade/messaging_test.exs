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
end
