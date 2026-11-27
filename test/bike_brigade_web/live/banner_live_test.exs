defmodule BikeBrigadeWeb.BannerLiveTest do
  use BikeBrigadeWeb.ConnCase

  import Phoenix.LiveViewTest

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

  test "expired banners are shown in their own tab, most recent first", ctx do
    {:ok, view, _html} = live(ctx.conn, ~p"/banners")

    refute render(view) =~ "Old expired"

    element(view, "#banners-tab-expired") |> render_click()
    assert row_ids(view) == ids([ctx.recent, ctx.old])
    refute render(view) =~ "Zulu active"

    element(view, "#banners-tab-current") |> render_click()
    assert row_ids(view) == ids([ctx.active, ctx.soon, ctx.later])
  end
end
