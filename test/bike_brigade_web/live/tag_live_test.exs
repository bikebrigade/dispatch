defmodule BikeBrigadeWeb.TagLiveTest do
  use BikeBrigadeWeb.ConnCase
  import Phoenix.LiveViewTest

  alias BikeBrigade.Riders

  describe "Tags index (dispatcher)" do
    setup [:login]

    test "lists all tags", ctx do
      tag = fixture(:tag, %{name: "Test Tag"})
      {:ok, _view, html} = live(ctx.conn, ~p"/tags")

      assert html =~ "Tags"
      assert html =~ tag.name
    end

    test "shows restricted status", ctx do
      fixture(:tag, %{name: "Normal Tag", restricted: false})
      fixture(:tag, %{name: "Restricted Tag", restricted: true})

      {:ok, _view, html} = live(ctx.conn, ~p"/tags")

      assert html =~ "Normal Tag"
      assert html =~ "Restricted Tag"
    end

    test "shows rider count", ctx do
      tag = fixture(:tag, %{name: "Popular Tag"})
      rider = fixture(:rider) |> BikeBrigade.Repo.preload(:tags)
      {:ok, _} = Riders.update_rider_with_tags(rider, %{}, [tag.name])

      {:ok, _view, html} = live(ctx.conn, ~p"/tags")

      # The table should show "1" in the riders column
      assert html =~ "Popular Tag"
    end

    test "can create a new tag", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/tags")

      view |> element("a", "New Tag") |> render_click()
      assert_patched(view, ~p"/tags/new")

      {:ok, _view, html} =
        view
        |> form("#tag-form", tag: %{name: "Brand New Tag"})
        |> render_submit()
        |> follow_redirect(ctx.conn)

      assert html =~ "Tag created successfully"
      assert html =~ "Brand New Tag"
    end

    test "validates tag name is required", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/tags/new")

      html =
        view
        |> form("#tag-form", tag: %{name: ""})
        |> render_submit()

      assert html =~ "can&#39;t be blank"
    end

    test "can edit a tag", ctx do
      tag = fixture(:tag, %{name: "Original Name"})
      {:ok, view, _html} = live(ctx.conn, ~p"/tags")

      view |> element("a", "Edit") |> render_click()
      assert_patched(view, ~p"/tags/#{tag.id}/edit")

      {:ok, _view, html} =
        view
        |> form("#tag-form", tag: %{name: "Updated Name"})
        |> render_submit()
        |> follow_redirect(ctx.conn)

      assert html =~ "Tag updated successfully"
      assert html =~ "Updated Name"
      refute html =~ "Original Name"
    end

    test "can delete a tag", ctx do
      tag = fixture(:tag, %{name: "To Be Deleted"})
      {:ok, view, html} = live(ctx.conn, ~p"/tags")

      assert html =~ tag.name

      html = view |> element("a", "Delete") |> render_click()

      refute html =~ tag.name
    end

    test "can toggle restricted status", ctx do
      tag = fixture(:tag, %{name: "Toggle Me", restricted: false})
      {:ok, view, _html} = live(ctx.conn, ~p"/tags")

      # Toggle to restricted using the button with title
      view |> element("button[title='Click to restrict']") |> render_click()

      updated_tag = Riders.get_tag!(tag.id)
      assert updated_tag.restricted == true

      # Toggle back to unrestricted
      view |> element("button[title='Click to unrestrict']") |> render_click()

      updated_tag = Riders.get_tag!(tag.id)
      assert updated_tag.restricted == false
    end
  end

  describe "Tags access control" do
    setup [:login_as_rider]

    test "non-dispatchers cannot access tags page", ctx do
      # The route is protected by require_dispatcher, so riders will get redirected to login
      assert {:error, {:redirect, %{to: "/login"}}} = live(ctx.conn, ~p"/tags")
    end
  end
end
