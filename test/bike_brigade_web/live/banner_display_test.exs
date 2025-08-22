defmodule BikeBrigadeWeb.BannerDisplayTest do
  use BikeBrigadeWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  describe "Banner display on rider home page" do
    setup ctx do
      login_as_rider(ctx)
    end

    test "shows active banners at top of page", ctx do
      now = DateTime.utc_now()

      # Create an active banner
      fixture(:banner, %{
        message: "Important delivery update!",
        enabled: true,
        turn_on_at: DateTime.add(now, -1, :hour),
        turn_off_at: DateTime.add(now, 1, :hour)
      })

      # Create a second active banner
      fixture(:banner, %{
        message: "Weather alert for today",
        enabled: true,
        turn_on_at: DateTime.add(now, -30, :minute),
        turn_off_at: DateTime.add(now, 2, :hour)
      })

      {:ok, _live, html} = live(ctx.conn, ~p"/home")

      assert html =~ "Important delivery update!"
      assert html =~ "Weather alert for today"
      assert html =~ "Important Notice"
      assert html =~ "📢"
    end

    test "does not show inactive banners", ctx do
      now = DateTime.utc_now()

      # Create a future banner
      fixture(:banner, %{
        message: "Future banner",
        enabled: true,
        turn_on_at: DateTime.add(now, 1, :hour),
        turn_off_at: DateTime.add(now, 2, :hour)
      })

      # Create a past banner
      fixture(:banner, %{
        message: "Past banner",
        enabled: true,
        turn_on_at: DateTime.add(now, -2, :hour),
        turn_off_at: DateTime.add(now, -1, :hour)
      })

      # Create a disabled banner
      fixture(:banner, %{
        message: "Disabled banner",
        enabled: false,
        turn_on_at: DateTime.add(now, -1, :hour),
        turn_off_at: DateTime.add(now, 1, :hour)
      })

      {:ok, _live, html} = live(ctx.conn, ~p"/home")

      refute html =~ "Future banner"
      refute html =~ "Past banner"
      refute html =~ "Disabled banner"
    end

    test "shows no banners when none are active", ctx do
      # Don't create any banners
      {:ok, _live, html} = live(ctx.conn, ~p"/home")

      # Should not have any banner HTML
      refute html =~ "Important Notice"
      refute html =~ "📢"
    end

    test "multiple active banners are all displayed", ctx do
      now = DateTime.utc_now()

      # Create multiple active banners
      for i <- 1..3 do
        fixture(:banner, %{
          message: "Banner #{i}",
          enabled: true,
          turn_on_at: DateTime.add(now, -1, :hour),
          turn_off_at: DateTime.add(now, 1, :hour)
        })
      end

      {:ok, _live, html} = live(ctx.conn, ~p"/home")

      assert html =~ "Banner 1"
      assert html =~ "Banner 2"
      assert html =~ "Banner 3"
    end
  end

  describe "Real-time banner updates on rider home page" do
    setup ctx do
      login_as_rider(ctx)
    end

    test "updates banner display in real-time when banner is created", ctx do
      {:ok, live, html} = live(ctx.conn, ~p"/home")

      # Initially no banners
      refute html =~ "New banner message"

      # Create a new active banner
      now = DateTime.utc_now()

      {:ok, _banner} =
        BikeBrigade.Notifications.create_banner(%{
          message: "New banner message",
          enabled: true,
          turn_on_at: DateTime.add(now, -1, :hour),
          turn_off_at: DateTime.add(now, 1, :hour),
          created_by_id: fixture(:user, %{is_dispatcher: true}).id
        })

      # The live view should automatically update and show the new banner
      assert render(live) =~ "New banner message"
    end

    test "updates banner display in real-time when banner is updated", ctx do
      now = DateTime.utc_now()

      banner =
        fixture(:banner, %{
          message: "Original message",
          enabled: true,
          turn_on_at: DateTime.add(now, -1, :hour),
          turn_off_at: DateTime.add(now, 1, :hour)
        })

      {:ok, live, html} = live(ctx.conn, ~p"/home")

      # Initially shows original message
      assert html =~ "Original message"
      refute html =~ "Updated message"

      # Update the banner
      {:ok, _updated_banner} =
        BikeBrigade.Notifications.update_banner(banner, %{
          message: "Updated message"
        })

      # The live view should automatically update
      updated_html = render(live)
      assert updated_html =~ "Updated message"
      refute updated_html =~ "Original message"
    end

    test "updates banner display in real-time when banner is deleted", ctx do
      now = DateTime.utc_now()

      banner =
        fixture(:banner, %{
          message: "Banner to delete",
          enabled: true,
          turn_on_at: DateTime.add(now, -1, :hour),
          turn_off_at: DateTime.add(now, 1, :hour)
        })

      {:ok, live, html} = live(ctx.conn, ~p"/home")

      # Initially shows the banner
      assert html =~ "Banner to delete"

      # Delete the banner
      {:ok, _} = BikeBrigade.Notifications.delete_banner(banner)

      # The live view should automatically update and hide the banner
      updated_html = render(live)
      refute updated_html =~ "Banner to delete"
    end

    test "updates banner display when banner becomes inactive due to time", ctx do
      # This test verifies that when a banner's time window expires,
      # it gets removed from the display on the next update
      now = DateTime.utc_now()

      # Create a banner that will be active initially
      banner =
        fixture(:banner, %{
          message: "Soon to expire",
          enabled: true,
          turn_on_at: DateTime.add(now, -1, :hour),
          turn_off_at: DateTime.add(now, 1, :hour)
        })

      {:ok, live, html} = live(ctx.conn, ~p"/home")

      # Initially shows the banner
      assert html =~ "Soon to expire"

      # Update the banner to be expired (simulate time passing)
      {:ok, _} =
        BikeBrigade.Notifications.update_banner(banner, %{
          # Expired 1 minute ago
          turn_off_at: DateTime.add(now, -1, :minute)
        })

      # The live view should automatically update and hide the expired banner
      updated_html = render(live)
      refute updated_html =~ "Soon to expire"
    end

    test "updates banner display when banner is disabled", ctx do
      now = DateTime.utc_now()

      banner =
        fixture(:banner, %{
          message: "Active banner",
          enabled: true,
          turn_on_at: DateTime.add(now, -1, :hour),
          turn_off_at: DateTime.add(now, 1, :hour)
        })

      {:ok, live, html} = live(ctx.conn, ~p"/home")

      # Initially shows the banner
      assert html =~ "Active banner"

      # Disable the banner
      {:ok, _} = BikeBrigade.Notifications.update_banner(banner, %{enabled: false})

      # The live view should automatically update and hide the disabled banner
      updated_html = render(live)
      refute updated_html =~ "Active banner"
    end
  end
end
