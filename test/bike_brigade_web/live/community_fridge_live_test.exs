defmodule BikeBrigadeWeb.CommunityFridgeLiveTest do
  use BikeBrigadeWeb.ConnCase
  import Phoenix.LiveViewTest

  alias BikeBrigade.MediaStorage.FakeMediaStorage

  describe "Community Fridges index (dispatcher)" do
    setup [:login]

    test "lists all community fridges", ctx do
      fridge = fixture(:community_fridge, %{name: "Test Fridge"})
      {:ok, _view, html} = live(ctx.conn, ~p"/community_fridges")

      assert html =~ "Community Fridges"
      assert html =~ fridge.name
    end

    test "can create a new community fridge", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/community_fridges")

      view |> element("a", "New Community Fridge") |> render_click()
      assert_patched(view, ~p"/community_fridges/new")

      {:ok, _view, html} =
        view
        |> form("#community-fridge-form", community_fridge: %{name: "Brand New Fridge"})
        |> render_submit()
        |> follow_redirect(ctx.conn)

      assert html =~ "Community fridge created successfully"
      assert html =~ "Brand New Fridge"
    end

    test "validates name is required", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/community_fridges/new")

      html =
        view
        |> form("#community-fridge-form", community_fridge: %{name: ""})
        |> render_submit()

      assert html =~ "can&#39;t be blank"
    end

    test "can edit a community fridge", ctx do
      fridge = fixture(:community_fridge, %{name: "Original Fridge"})
      {:ok, view, _html} = live(ctx.conn, ~p"/community_fridges")

      view |> element("a", "Edit") |> render_click()
      assert_patched(view, ~p"/community_fridges/#{fridge.id}/edit")

      {:ok, _view, html} =
        view
        |> form("#community-fridge-form", community_fridge: %{name: "Updated Fridge"})
        |> render_submit()
        |> follow_redirect(ctx.conn)

      assert html =~ "Community fridge updated successfully"
      assert html =~ "Updated Fridge"
      refute html =~ "Original Fridge"
    end

    test "can navigate directly to edit page", ctx do
      fridge = fixture(:community_fridge, %{name: "Edit Me"})
      {:ok, _view, html} = live(ctx.conn, ~p"/community_fridges/#{fridge.id}/edit")

      assert html =~ "Edit Fridge"
    end

    test "edit preserves existing values", ctx do
      fridge =
        fixture(:community_fridge, %{
          name: "Preserve Me",
          description: "Some description",
          active: true,
          pair_preferred: true
        })

      {:ok, _view, html} = live(ctx.conn, ~p"/community_fridges/#{fridge.id}/edit")

      assert html =~ "Preserve Me"
      assert html =~ "Some description"
    end
  end

  describe "Community Fridge photo upload" do
    setup [:login]

    test "shows existing photo in edit form", ctx do
      fridge =
        fixture(:community_fridge, %{
          name: "Photo Fridge",
          photo: "https://example.com/fridge.jpg"
        })

      {:ok, _view, html} = live(ctx.conn, ~p"/community_fridges/#{fridge.id}/edit")

      assert html =~ "https://example.com/fridge.jpg"
    end

    test "renders upload dropzone", ctx do
      fixture(:community_fridge, %{name: "Upload Fridge"})
      {:ok, view, _html} = live(ctx.conn, ~p"/community_fridges/new")

      html = render(view)
      assert html =~ "Upload a file"
      assert html =~ "or drag and drop"
      assert html =~ "PNG, JPG, GIF"
    end

    test "shows pending upload preview after file is selected", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/community_fridges/new")

      upload =
        file_input(view, "#community-fridge-form", :photo, [
          %{name: "fridge.jpg", content: <<0, 1, 2>>, type: "image/jpeg"}
        ])

      render_upload(upload, "fridge.jpg", 100)

      html = render(view)
      assert html =~ "fridge.jpg"
    end

    test "can cancel a pending upload", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/community_fridges/new")

      upload =
        file_input(view, "#community-fridge-form", :photo, [
          %{name: "fridge.jpg", content: <<0, 1, 2>>, type: "image/jpeg"}
        ])

      render_upload(upload, "fridge.jpg", 100)
      assert render(view) =~ "fridge.jpg"

      view |> element("button[aria-label='cancel']") |> render_click()
      refute render(view) =~ "fridge.jpg"
    end

  end

  describe "Community Fridges access control" do
    setup [:login_as_rider]

    test "non-dispatchers cannot access community fridges page", ctx do
      assert {:error, {:redirect, %{to: "/login"}}} = live(ctx.conn, ~p"/community_fridges")
    end
  end
end
