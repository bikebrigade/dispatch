defmodule BikeBrigadeWeb.OpportunityLiveTest do
  use BikeBrigadeWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "Index" do
    setup [:create_opportunity, :login]

    test "lists opportunities for week opportunities", %{conn: conn, opportunity: opportunity, program: program} do
      {:ok, _index_live, html} = live(conn, Routes.opportunity_index_path(conn, :index))
      assert html =~ "Opportunities"
      assert html =~ program.name
      assert html =~ opportunity.signup_link
    end

    test "redirects to show opportunity", %{conn: conn, opportunity: opportunity, program: program} do
      {:ok, view, _html} = live(conn, Routes.opportunity_index_path(conn, :index))

      # Select a program

      view
      |> element("a", program.name)
      |> render_click()

      assert_redirected(view, "/programs/#{program.id}")
    end

    test "can add new opportunity", %{conn: conn, opportunity: opportunity, program: program} do
      {:ok, view, html} = live(conn, Routes.opportunity_index_path(conn, :index))
      assert html =~ "New Signup Link"

      view
      |> element("button", "New Signup Link")
      |> render_click()

      view
        |> form("#opportunity-form-new",
        opportunity_form: %{
              program_id: "",
              delivery_date: "2021-12-13",
              start_time: "15:00pm",
              end_time: "17:00pm",
              signup_link: "https://www.example.com/"
            }
        )

        |> render_submit()
    end
  end
end
