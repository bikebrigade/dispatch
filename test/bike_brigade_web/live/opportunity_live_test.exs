defmodule BikeBrigadeWeb.OpportunityLiveTest do
  use BikeBrigadeWeb.ConnCase

  alias BikeBrigade.Repo.Seeds.Toronto

  import Phoenix.LiveViewTest

  describe "Index" do
    setup [:create_opportunity, :login]

    test "lists opportunities for week opportunities", %{
      conn: conn,
      opportunity: opportunity,
      program: program
    } do
      {:ok, _index_live, html} = live(conn, Routes.opportunity_index_path(conn, :index))
      assert html =~ "Opportunities"
      assert html =~ program.name
      assert html =~ opportunity.signup_link
    end

    test "redirects to show opportunity", %{conn: conn, program: program} do
      {:ok, view, _html} = live(conn, Routes.opportunity_index_path(conn, :index))

      # Select a program

      view
      |> element("a", program.name)
      |> render_click()

      assert_redirected(view, "/programs/#{program.id}")
    end

    test "can add new opportunity", %{conn: conn, opportunity: opportunity, program: program} do
      {:ok, view, html} = live(conn, Routes.opportunity_index_path(conn, :index))

      view
      |> element("a", "New")
      |> render_click()

      assert_patched(view, "/opportunities/new")

      link = Faker.Internet.url()
      location = Toronto.random_location()

      assert view
             |> form("#opportunity-form",
               opportunity_form: %{
                 delivery_date: "2021-12-13",
                 start_time: "15:00pm",
                 end_time: "17:00pm",
                 signup_link: link,
                 location: %{
                   address: location.address
                 }
               }
             )
             |> render_submit() =~ link
    end
  end
end
