defmodule BikeBrigadeWeb.UserLiveTest do
  use BikeBrigadeWeb.ConnCase
  import Phoenix.LiveViewTest

  setup [:login]

  defp find_user_row(html, name) do
    html
    |> Floki.parse_fragment!()
    |> Floki.find(".user-row")
    |> Enum.find(fn row -> Floki.text(row) =~ name end)
  end

  describe "Users :index" do
    test "Clicking edit patches to 'users/:id/edit'", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/users")
      view |> element("a", ~r"Edit .* #{ctx.user.name}") |> render_click()
      assert_patched(view, ~p"/users/#{ctx.user.id}/edit")
    end

    test "Deleting a user works as intended", ctx do
      # create a new user so we are testing not just deleting the user
      # created by setup [:login]
      user = fixture(:user, %{is_dispatcher: true})
      {:ok, view, html} = live(ctx.conn, ~p"/users")
      assert html =~ user.name
      html = view |> element("a", ~r"Delete .* #{user.name}") |> render_click()
      refute find_user_row(html, user.name)
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

      {:ok, _view, html} = live(ctx.conn, ~p"/users?dispatchers_only=false")

      rider_row = find_user_row(html, rider.name)
      assert rider_row
      assert Floki.text(rider_row) =~ "🚴"
    end

    test "Can make a user into a dispatcher", ctx do
      # first, upgrade a rider to a user.
      rider = fixture(:rider)
      {:ok, view, _html} = live(ctx.conn, ~p"/riders/#{rider.id}/show/edit")
      view |> element("a", "Enable") |> render_click()

      # find them in the users view (show all users, not just dispatchers), and click "edit"
      {:ok, view, _html} = live(ctx.conn, ~p"/users?dispatchers_only=false")
      view |> element("a", ~r"Edit .* #{rider.name}") |> render_click()

      {:ok, _view, html} =
        view
        |> form("#user-form", user: %{"is_dispatcher" => true})
        |> render_submit()
        |> follow_redirect(ctx.conn)

      rider_row = find_user_row(html, rider.name)
      assert rider_row
      assert Floki.text(rider_row) =~ ~r/🧑‍🔧.*🚴/s
    end
  end
end
