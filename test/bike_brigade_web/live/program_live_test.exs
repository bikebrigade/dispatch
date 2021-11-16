defmodule BikeBrigadeWeb.ProgramLiveTest do
  use BikeBrigadeWeb.ConnCase

  import Phoenix.LiveViewTest

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
  end
end
