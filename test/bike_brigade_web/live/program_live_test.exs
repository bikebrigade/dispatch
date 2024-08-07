defmodule BikeBrigadeWeb.ProgramLiveTest do
  use BikeBrigadeWeb.ConnCase

  import Phoenix.LiveViewTest

  alias BikeBrigade.Delivery

  describe "Index" do
    setup [:create_program, :login]

    test "lists programs for week programs", %{conn: conn, program: program} do
      {:ok, _index_live, html} = live(conn, ~p"/programs")

      assert html =~ "Programs"
      assert html =~ program.name
    end

    test "redirects to show program", %{conn: conn, program: program} do
      {:ok, view, _html} = live(conn, ~p"/programs")

      # Select the program

      view
      |> element("a", ~r|#{program.name}\s+|)
      |> render_click()

      assert_redirected(view, "/programs/#{program.id}")
    end

    test "New Program button goes to new program route", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/programs")

      view |> element("a", "New Program") |> render_click()
      assert_patched(view, "/programs/new")
    end

    # Click on Edit

    test "redirects to edit program", %{conn: conn, program: program} do
      {:ok, view, _html} = live(conn, ~p"/programs")

      view
      |> element("# a", "Edit")
      |> render_click()

      assert_patched(view, "/programs/#{program.id}/edit")
    end

    # Edit form

    test "can edit a program", %{conn: conn, program: program} do
      {:ok, view, _html} = live(conn, ~p"/programs/#{program}/show/edit")

      {:ok, _view, html} =
        view
        |> form("#program-form",
          program_form: %{
            program: %{
              name: "Foodies",
              campaign_blurb: "Lorem Ipsum is simply dummy text",
              description: "Food for all foodies",
              contact_name: "Zizo",
              contact_email: "zizo@gmail.com"
            }
          }
        )
        |> render_submit()
        |> follow_redirect(conn)

      assert html =~ "Foodies"

      # get an ID of a program.
      updated_program = Delivery.get_program!(program.id)
      assert updated_program.name == "Foodies"
    end

    # New item

    test "can add new item", %{conn: conn, program: program} do
      {:ok, view, html} = live(conn, ~p"/programs/#{program}/edit")

      # We don't have an item called Pasta
      refute html =~ "Pasta"

      # We have forms for only one item
      assert view
             |> has_element?("[name='program_form[program][items][0][name]']")

      refute view
             |> has_element?("[name='program_form[program][items][1][name]']")

      # Click on New Item
      view
      |> element("#program-form a", "New Item")
      |> render_click()

      # We have a form for a second item
      assert view
             |> has_element?("[name='program_form[program][items][1][name]']")

      [item] = program.items

      {:ok, _view, _html} =
        view
        |> form("#program-form",
          program_form: %{
            program: %{
              items: %{0 => %{id: item.id, name: "Pasta"}, 1 => %{name: "Soup"}}
            }
          }
        )
        |> render_submit()
        |> follow_redirect(conn)

      # Open the edit page again to make sure we have the new item type
      {:ok, _view, html} = live(conn, ~p"/programs/#{program}/edit")

      assert html =~ "Pasta"
      assert html =~ "Soup"
    end
  end
end
