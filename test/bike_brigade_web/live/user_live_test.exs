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

  describe "Users :new / :edit" do
    # REVIEW: users/new doesn't seem to be working locally yet.
    @tag :skip
    test "Can create a user", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/users/new")

      res =
        view
        |> form("#user-form")
        |> render_submit(%{
          name: "Brandon",
          email: "brandom@coolhats.com"
        })
    end

    test "Can edit a user", ctx do
      {:ok, view, html} = live(ctx.conn, ~p"/users/#{ctx.user.id}/edit")
      view |> element("#user-form") |> dbg()

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
  end
end
