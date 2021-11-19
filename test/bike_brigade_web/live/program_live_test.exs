defmodule BikeBrigadeWeb.ProgramLiveTest do
  use BikeBrigadeWeb.ConnCase

  import Phoenix.LiveViewTest

  alias BikeBrigade.Delivery

  describe "Index" do
    setup [:create_program, :login]

    test "lists programs for week programs", %{conn: conn, program: program} do
      {:ok, index_live, html} = live(conn, Routes.program_index_path(conn, :index))
      assert html =~ "Programs"
      assert html =~ program.name
    end

    test "redirects to show program", %{conn: conn, program: program} do
      {:ok, view, html} = live(conn, Routes.program_index_path(conn, :index))

      # Select the program

      view
      |> element("##{program.id} a", program.name)
      |> render_click()

      assert_redirected(view, "/programs/#{program.id}")
    end

    # Click on Edit

    test "redirects to edit program", %{conn: conn, program: program} do
      {:ok, view, _html} = live(conn, Routes.program_index_path(conn, :index))

      view
      |> element("##{program.id} a", "Edit")
      |> render_click()

      assert_patched(view, "/programs/#{program.id}/edit")
    end

    # Edit form

    test "can edit a program", %{conn: conn, program: program} do
      {:ok, view, html} = live(conn, Routes.program_show_path(conn, :edit, program))

      {:ok, view, html} =
        view
        |> form("#program-form",
          program_form: %{
            program: %{
              name: "Food",
              campaign_blurb: "Lorem Ipsum is simply dummy text",
              description: "Food for all foodies",
              contact_name: "Zizo",
              contact_email: "zizo@gmail.com"
            }
          }
        )
        |> render_submit()
        |> follow_redirect(conn)

      assert html =~ "Food"

      view
      |> open_browser()

      # get an ID of a program.
      updated_program = Delivery.get_program!(program.id)
      assert updated_program.name == "Foodies"
    end

    # New item

    test "can add new item", %{conn: conn, program: program} do
      {:ok, view, html} = live(conn, Routes.program_index_path(conn, :edit, program))

      # Click on New Item
      view
      |> element("#program-form a", "New Item")
      |> render_click()

      assert_patched(view, "/programs/#{program.id}/items/new")

      {:ok, view, html} =
        view
        |> form("#item-form",
              item: %{
              name: "good food",
              plural_name: "Food Hampers",
              description: "Awesome food hamper",
              category: "Food Hamper"
            }
        )
        |> render_submit()
        |> follow_redirect(conn)

    end
  end
end
