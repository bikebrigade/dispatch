defmodule BikeBrigadeWeb.BannerLiveTest do
  use BikeBrigadeWeb.ConnCase

  import Phoenix.LiveViewTest
  import Ecto.Query, only: [from: 2]

  setup :login

  setup do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    hours = &DateTime.add(now, &1, :hour)

    later =
      fixture(:banner, %{message: "Alpha later", turn_on_at: hours.(5), turn_off_at: hours.(6)})

    active =
      fixture(:banner, %{message: "Zulu active", turn_on_at: hours.(-1), turn_off_at: hours.(1)})

    soon =
      fixture(:banner, %{message: "Mike soon", turn_on_at: hours.(2), turn_off_at: hours.(3)})

    old =
      fixture(:banner, %{
        message: "Old expired",
        turn_on_at: hours.(-48),
        turn_off_at: hours.(-47)
      })

    recent =
      fixture(:banner, %{
        message: "Recent expired",
        turn_on_at: hours.(-5),
        turn_off_at: hours.(-4)
      })

    %{later: later, active: active, soon: soon, old: old, recent: recent}
  end

  defp row_ids(view) do
    view
    |> render()
    |> Floki.parse_document!()
    |> Floki.find("#banners tbody tr")
    |> Floki.attribute("id")
  end

  defp ids(banners), do: Enum.map(banners, &"banners-#{&1.id}")

  test "shows current banners sorted by start date by default", ctx do
    {:ok, view, _html} = live(ctx.conn, ~p"/banners")

    assert row_ids(view) == ids([ctx.active, ctx.soon, ctx.later])
  end

  test "can sort by message and toggle direction", ctx do
    {:ok, view, _html} = live(ctx.conn, ~p"/banners")

    element(view, "[data-test-id=sort_message]") |> render_click()
    assert row_ids(view) == ids([ctx.later, ctx.soon, ctx.active])

    element(view, "[data-test-id=sort_message]") |> render_click()
    assert row_ids(view) == ids([ctx.active, ctx.soon, ctx.later])
  end

  test "can toggle start date sort to descending", ctx do
    {:ok, view, _html} = live(ctx.conn, ~p"/banners")

    element(view, "[data-test-id=sort_turn_on_at]") |> render_click()
    assert row_ids(view) == ids([ctx.later, ctx.soon, ctx.active])
  end

  test "expired banners are shown in their own tab, most recently expired first", ctx do
    # Started earliest but expired most recently, so it sorts first despite its start time
    long_running =
      fixture(:banner, %{
        message: "Long running",
        turn_on_at: DateTime.add(DateTime.utc_now(), -100, :hour),
        turn_off_at: DateTime.add(DateTime.utc_now(), -1, :hour)
      })

    {:ok, view, _html} = live(ctx.conn, ~p"/banners")

    refute render(view) =~ "Old expired"

    element(view, "#banners-tab-expired") |> render_click()
    assert row_ids(view) == ids([long_running, ctx.recent, ctx.old])
    refute render(view) =~ "Zulu active"

    element(view, "#banners-tab-current") |> render_click()
    assert row_ids(view) == ids([ctx.active, ctx.soon, ctx.later])
  end

  test "switching tabs picks up banners that expired after the page loaded", ctx do
    {:ok, view, _html} = live(ctx.conn, ~p"/banners")
    assert row_ids(view) == ids([ctx.active, ctx.soon, ctx.later])

    now = DateTime.utc_now()

    # Simulate the banner expiring while the page is open
    BikeBrigade.Repo.update_all(
      from(b in BikeBrigade.Notifications.Banner, where: b.id == ^ctx.active.id),
      set: [turn_on_at: DateTime.add(now, -3, :hour), turn_off_at: DateTime.add(now, -2, :hour)]
    )

    element(view, "#banners-tab-expired") |> render_click()
    assert "banners-#{ctx.active.id}" in row_ids(view)
    assert has_element?(view, "#banners-tab-current .badge", "2")

    assert has_element?(
             view,
             ~s(#banners-panel[role="tabpanel"][aria-labelledby="banners-tab-expired"])
           )
  end
end
