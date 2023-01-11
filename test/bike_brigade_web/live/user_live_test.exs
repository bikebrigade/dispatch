defmodule BikeBrigadeWeb.UserLiveTest do
  use BikeBrigadeWeb.ConnCase
  import Phoenix.LiveViewTest

  setup [:login]

  describe "Users :index" do
    test "Clicking edit patches to 'users/:id/edit'", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/users")
      view |> element(".user-row:first-child a", "Edit") |> render_click()
      assert_patched(view, ~p"/users/#{ctx.user.id}/edit")
    end

    test "Deleting a user works as intended", ctx do
      # create a new user so we are testing not just deleting the user
      # created by setup [:login]
      user = fixture(:user, %{is_dispatcher: true})
      {:ok, view, html} = live(ctx.conn, ~p"/users")
      assert html =~ user.name
      html = view |> element(".user-row:nth-child(2) a", "Delete") |> render_click()
      refute html =~ user.name
    end
  end

  describe "Users new / edit" do
    test "Can edit a user", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/users/#{ctx.user.id}/edit")
      view |> element("#user-form") 

      {:ok, _view, html} =
        view
        |> form("#user-form")
        |> render_submit(%{
          user: %{
            name: ctx.user.name <> " the second",
            email: ctx.user.email
          }
        })
        |> follow_redirect(ctx.conn)

      assert html =~ ctx.user.name <> " the second"
    end

    test "Can make a rider into a user", ctx do
      rider = fixture(:rider)
      {:ok, view, html} = live(ctx.conn, ~p"/riders/#{rider.id}/show/edit")
      assert html =~ "Login not Enabled"
      view |> element("a", "Enable") |> render_click()
      assert_redirected(view, ~p"/riders/#{rider.id}")

      {:ok, _view, html} = live(ctx.conn, ~p"/users")

      new_rider_user_row_text =
        assert html
               |> Floki.parse_fragment!()
               |> Floki.find(".user-row")
               |> List.last()
               |> Floki.text()

      assert new_rider_user_row_text =~ "🚴"
      assert new_rider_user_row_text =~ rider.name
    end

    test "Can make a user into a dispatcher", ctx do
      # first, upgrade a rider to a user.
      rider = fixture(:rider)
      {:ok, view, _html} = live(ctx.conn, ~p"/riders/#{rider.id}/show/edit")
      view |> element("a", "Enable") |> render_click()

      # find them in the users view,  and click "edit"
      {:ok, view, _html} = live(ctx.conn, ~p"/users")
      view |> element("a", ~r"Edit .* #{rider.name}") |> render_click()

      {:ok, view, _html} =
        view
        |> form("#user-form", user: %{"is_dispatcher" => true})
        |> render_submit()
        |> follow_redirect(ctx.conn)

      assert view
             |> render()
             |> Floki.parse_fragment!()
             |> Floki.find(".user-row")
             |> List.last()
             |> Floki.text() =~
               ~r/🧑‍🔧.*🚴/s
    end
  end
end
