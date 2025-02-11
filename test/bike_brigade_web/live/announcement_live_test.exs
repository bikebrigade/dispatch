defmodule BikeBrigadeWeb.AnnouncementLiveTest do
  use BikeBrigadeWeb.ConnCase

  import Phoenix.LiveViewTest
  import BikeBrigade.DeliveryFixtures

  @create_attrs %{message: "some message", turn_on_at: "2025-02-10T22:38:00.000000Z", turn_off_at: "2025-02-10T22:38:00.000000Z"}
  @update_attrs %{message: "some updated message", turn_on_at: "2025-02-11T22:38:00.000000Z", turn_off_at: "2025-02-11T22:38:00.000000Z"}
  @invalid_attrs %{message: nil, turn_on_at: nil, turn_off_at: nil}

  defp create_announcement(_) do
    announcement = announcement_fixture()
    %{announcement: announcement}
  end

  describe "Index" do
    setup [:create_announcement]

    test "lists all announcements", %{conn: conn, announcement: announcement} do
      {:ok, _index_live, html} = live(conn, ~p"/announcements")

      assert html =~ "Listing Announcements"
      assert html =~ announcement.message
    end

    test "saves new announcement", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/announcements")

      assert index_live |> element("a", "New Announcement") |> render_click() =~
               "New Announcement"

      assert_patch(index_live, ~p"/announcements/new")

      assert index_live
             |> form("#announcement-form", announcement: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#announcement-form", announcement: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/announcements")

      html = render(index_live)
      assert html =~ "Announcement created successfully"
      assert html =~ "some message"
    end

    test "updates announcement in listing", %{conn: conn, announcement: announcement} do
      {:ok, index_live, _html} = live(conn, ~p"/announcements")

      assert index_live |> element("#announcements-#{announcement.id} a", "Edit") |> render_click() =~
               "Edit Announcement"

      assert_patch(index_live, ~p"/announcements/#{announcement}/edit")

      assert index_live
             |> form("#announcement-form", announcement: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#announcement-form", announcement: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/announcements")

      html = render(index_live)
      assert html =~ "Announcement updated successfully"
      assert html =~ "some updated message"
    end

    test "deletes announcement in listing", %{conn: conn, announcement: announcement} do
      {:ok, index_live, _html} = live(conn, ~p"/announcements")

      assert index_live |> element("#announcements-#{announcement.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#announcements-#{announcement.id}")
    end
  end

  describe "Show" do
    setup [:create_announcement]

    test "displays announcement", %{conn: conn, announcement: announcement} do
      {:ok, _show_live, html} = live(conn, ~p"/announcements/#{announcement}")

      assert html =~ "Show Announcement"
      assert html =~ announcement.message
    end

    test "updates announcement within modal", %{conn: conn, announcement: announcement} do
      {:ok, show_live, _html} = live(conn, ~p"/announcements/#{announcement}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Announcement"

      assert_patch(show_live, ~p"/announcements/#{announcement}/show/edit")

      assert show_live
             |> form("#announcement-form", announcement: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#announcement-form", announcement: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/announcements/#{announcement}")

      html = render(show_live)
      assert html =~ "Announcement updated successfully"
      assert html =~ "some updated message"
    end
  end
end
