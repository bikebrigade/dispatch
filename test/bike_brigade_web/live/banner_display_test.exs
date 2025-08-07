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
end
