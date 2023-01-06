defmodule BikeBrigadeWeb.OpportunityLiveTest do
  use BikeBrigadeWeb.ConnCase
  import Phoenix.LiveViewTest

  describe "Messages :index" do
    setup [:login, :create_rider]

    test "Adding new rider to message works", ctx do
      {:ok, view, _index} = live(ctx.conn, ~p"/messages/")
      view |> element("a", "New") |> render_click()
      assert_patch(view, ~p"/messages/new")

      view
      |> form("#sms_message-form")
      |> render_submit(%{
        "rider_ids" => [ctx.rider.id],
        "search" => "f",
        "sms_message" => %{"body" => "this is a test message"}
      })

      assert_redirected(view, ~p"/messages/#{ctx.rider.id}")

      {:ok, view, html} = live(ctx.conn, ~p"/messages/")
      assert html =~ "this is a test message"
    end
  end
end
