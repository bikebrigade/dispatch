defmodule BikeBrigade.AccountsTest do
  use BikeBrigade.DataCase

  alias BikeBrigade.Accounts

  describe "users" do
    alias BikeBrigade.Accounts.User

    @valid_attrs %{email: "some email", name: "some name", phone: "6475551234"}
    @update_attrs %{email: "some updated email", name: "some updated name", phone: "6475555678"}
    @invalid_attrs %{email: nil, name: nil, phone: nil}

    test "list_users/0 returns all users" do
      user = fixture(:user)
      assert Accounts.list_users() == [user]
    end

    test "get_user/1 returns the user with given id" do
      user = fixture(:user)
      assert Accounts.get_user(user.id) == user
    end

    test "get_user_by_phone/1 returns the user with given phone number" do
      user = fixture(:user)
      assert Accounts.get_user_by_phone(user.phone) == user
      assert Accounts.get_user_by_phone("6475559999") == nil
    end

    test "get_users/1 returns the users with given ids" do
      user = fixture(:user)
      assert Accounts.get_users([user.id]) == [user]
    end

    test "search_users/1 returns the users with a name matching the query" do
      user = fixture(:user)
      assert Accounts.search_users(user.name) == [user]
      assert Accounts.search_users(String.slice(user.name, 1..3)) == [user]
      assert Accounts.search_users("foobarbaz") == []
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Accounts.create_user_as_admin(@valid_attrs)
      assert user.email == "some email"
      assert user.name == "some name"
      assert user.phone == "+16475551234"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user_as_admin(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = fixture(:user)
      assert {:ok, %User{} = user} = Accounts.update_user(user, @update_attrs)
      assert user.email == "some updated email"
      assert user.name == "some updated name"
      assert user.phone == "+16475555678"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = fixture(:user)
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      assert user == Accounts.get_user(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = fixture(:user)
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert Accounts.get_user(user.id) == nil
    end

    test "change_user/1 returns a user changeset" do
      user = fixture(:user)
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end

    test "create_user_for_rider/1 creates a user for a rider" do
      rider = fixture(:rider)
      assert {:ok, %User{} = user} = Accounts.create_user_for_rider(rider)
      assert {user.name, user.phone, user.email} == {rider.name, rider.phone, rider.email}
      assert !user.is_dispatcher
    end
  end
end
