defmodule BikeBrigadeWeb.ProgramLiveTest do  #defining the module
  use BikeBrigadeWeb.ConnCase                #we are using BikeBrigadeWed.conncase

  import Phoenix.LiveViewTest                #we are importing Phoenix.LiveViewTest into our file

  alias BikeBrigade.Delivery                #We set up an alias for Delivery module so that we can use the module name in line 68

  describe "Index" do                       # Function call being called in line 12
    setup [:create_program, :login]         # is a call back function

    test "lists programs for week programs", %{conn: conn, program: program} do           #this defines a not implemented test a string. program and conn are variables
      {:ok, index_live, html} = live(conn, Routes.program_index_path(conn, :index))       # this is a function call being made in line 4
      assert html =~ "Programs"                                                           # thisis the name given when the element of program.name is found
      assert html =~ program.name                                                         #if the html contain an element of program.name
                                                                                          #and if it doed give it the name program.
    end                                                                                   #end of the test

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
