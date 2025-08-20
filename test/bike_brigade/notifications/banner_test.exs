defmodule BikeBrigade.Notifications.BannerTest do
  use BikeBrigade.DataCase, async: true

  alias BikeBrigade.Notifications

  describe "Banner CRUD operations" do
    test "create_banner with valid data" do
      turn_on_time = DateTime.utc_now()
      turn_off_time = DateTime.utc_now() |> DateTime.add(1, :day)
      user = fixture(:user, %{is_dispatcher: true})

      result =
        Notifications.create_banner(%{
          message: "foo",
          created_by_id: user.id,
          turn_on_at: turn_on_time,
          turn_off_at: turn_off_time
        })

      assert {:ok, banner} = result
      assert banner.message == "foo"
      assert banner.created_by_id == user.id
      assert banner.enabled == true
    end

    test "list_banners" do
      for _n <- 1..4 do
        fixture(:banner)
      end

      assert Enum.count(Notifications.list_banners()) == 4
    end

    test "update_banner" do
      b = fixture(:banner)
      {:ok, b2} = Notifications.update_banner(b, %{message: "bar"})
      assert b2.message == "bar"
    end

    test "delete_banner" do
      banner = fixture(:banner)
      assert {:ok, _} = Notifications.delete_banner(banner)

      assert_raise Ecto.NoResultsError, fn ->
        Notifications.get_banner!(banner.id)
      end
    end

    test "get_banner!" do
      banner = fixture(:banner)
      retrieved = Notifications.get_banner!(banner.id)
      assert retrieved.id == banner.id
      assert retrieved.message == banner.message
    end
  end

  describe "Banner validation" do
    test "cannot create banner where turn_on_at is after turn_off_at" do
      now = DateTime.utc_now()
      turn_on_time = now |> DateTime.add(2, :day)
      turn_off_time = now |> DateTime.add(1, :day)
      user = fixture(:user, %{is_dispatcher: true})

      result =
        Notifications.create_banner(%{
          message: "Invalid banner",
          created_by_id: user.id,
          turn_on_at: turn_on_time,
          turn_off_at: turn_off_time
        })

      assert {:error, changeset} = result
      assert "must be after turn on time" in errors_on(changeset).turn_off_at
    end

    test "cannot create banner where turn_on_at equals turn_off_at" do
      same_time = DateTime.utc_now()
      user = fixture(:user, %{is_dispatcher: true})

      result =
        Notifications.create_banner(%{
          message: "Invalid banner",
          created_by_id: user.id,
          turn_on_at: same_time,
          turn_off_at: same_time
        })

      assert {:error, changeset} = result
      assert "must be after turn on time" in errors_on(changeset).turn_off_at
    end

    test "requires message" do
      user = fixture(:user, %{is_dispatcher: true})
      now = DateTime.utc_now()

      result =
        Notifications.create_banner(%{
          created_by_id: user.id,
          turn_on_at: now,
          turn_off_at: DateTime.add(now, 1, :day)
        })

      assert {:error, changeset} = result
      assert "can't be blank" in errors_on(changeset).message
    end

    test "requires created_by_id" do
      now = DateTime.utc_now()

      result =
        Notifications.create_banner(%{
          message: "Test message",
          turn_on_at: now,
          turn_off_at: DateTime.add(now, 1, :day)
        })

      assert {:error, changeset} = result
      assert "can't be blank" in errors_on(changeset).created_by_id
    end

    test "requires turn_on_at and turn_off_at" do
      user = fixture(:user, %{is_dispatcher: true})

      result =
        Notifications.create_banner(%{
          message: "Test message",
          created_by_id: user.id
        })

      assert {:error, changeset} = result
      assert "can't be blank" in errors_on(changeset).turn_on_at
      assert "can't be blank" in errors_on(changeset).turn_off_at
    end
  end

  describe "list_active_banners" do
    test "returns only banners that are currently active and enabled" do
      now = DateTime.utc_now()

      # Active banner: started 1 hour ago, ends in 1 hour
      active_banner =
        fixture(:banner, %{
          message: "Active banner",
          enabled: true,
          turn_on_at: DateTime.add(now, -1, :hour),
          turn_off_at: DateTime.add(now, 1, :hour)
        })

      # Future banner: starts in 1 hour
      _future_banner =
        fixture(:banner, %{
          message: "Future banner",
          enabled: true,
          turn_on_at: DateTime.add(now, 1, :hour),
          turn_off_at: DateTime.add(now, 2, :hour)
        })

      # Past banner: ended 1 hour ago
      _past_banner =
        fixture(:banner, %{
          message: "Past banner",
          enabled: true,
          turn_on_at: DateTime.add(now, -2, :hour),
          turn_off_at: DateTime.add(now, -1, :hour)
        })

      # Disabled banner: would be active if enabled
      _disabled_banner =
        fixture(:banner, %{
          message: "Disabled banner",
          enabled: false,
          turn_on_at: DateTime.add(now, -1, :hour),
          turn_off_at: DateTime.add(now, 1, :hour)
        })

      active_banners = Notifications.list_active_banners()
      assert length(active_banners) == 1
      assert hd(active_banners).id == active_banner.id
      assert hd(active_banners).message == "Active banner"
    end

    test "returns empty list when no banners are active" do
      now = DateTime.utc_now()

      # All banners are in the past or future
      _past_banner =
        fixture(:banner, %{
          turn_on_at: DateTime.add(now, -2, :hour),
          turn_off_at: DateTime.add(now, -1, :hour)
        })

      _future_banner =
        fixture(:banner, %{
          turn_on_at: DateTime.add(now, 1, :hour),
          turn_off_at: DateTime.add(now, 2, :hour)
        })

      active_banners = Notifications.list_active_banners()
      assert length(active_banners) == 0
    end

    test "returns multiple active banners ordered by turn_on_at" do
      now = DateTime.utc_now()

      # Banner that started 2 hours ago
      earlier_banner =
        fixture(:banner, %{
          message: "Earlier banner",
          turn_on_at: DateTime.add(now, -2, :hour),
          turn_off_at: DateTime.add(now, 1, :hour)
        })

      # Banner that started 1 hour ago
      later_banner =
        fixture(:banner, %{
          message: "Later banner",
          turn_on_at: DateTime.add(now, -1, :hour),
          turn_off_at: DateTime.add(now, 1, :hour)
        })

      active_banners = Notifications.list_active_banners()
      assert length(active_banners) == 2
      # Should be ordered by turn_on_at ascending (earlier first)
      assert Enum.at(active_banners, 0).id == earlier_banner.id
      assert Enum.at(active_banners, 1).id == later_banner.id
    end
  end
end