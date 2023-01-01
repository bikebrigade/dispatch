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
      {:ok, _index_live, html} = live(conn, ~p"/opportunities")
      assert html =~ "Opportunities"
      assert html =~ program.name
      assert html =~ opportunity.signup_link
    end

    test "redirects to show opportunity", %{conn: conn, program: program} do
      {:ok, view, _html} = live(conn, ~p"/opportunities")

      # Select a program

      view
      |> element("a", ~r|#{program.name}\s+|)
      |> render_click()

      assert_redirected(view, "/programs/#{program.id}")
    end

    test "can add new opportunity", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/opportunities")

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

  describe "Index sorting of tables" do
    setup ctx do
      %{opportunity: opportunity1, program: program1} =
        create_opportunity(%{program_attrs: %{name: "A Program"}, opportunity_attrs: %{}})

      %{opportunity: opportunity2, program: program2} =
        create_opportunity(%{program_attrs: %{name: "Z Program"}, opportunity_attrs: %{}})

      ctx
      |> login()
      |> Map.put(:opportunities, [opportunity1, opportunity2])
      |> Map.put(:programs, [program1, program2])
    end

    test "opportunities can be sorted by program", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/opportunities")

      unsorted = get_rows(view, ".program-row-name")
      assert unsorted == Enum.map(ctx.programs, fn x -> x.name end)

      element(view, "[data-test-id=sort_program_name]") |> render_click()
      sorted = get_rows(view, ".program-row-name")

      assert sorted ==
               Enum.sort_by(ctx.programs, fn x -> x.name end, :desc)
               |> Enum.map(fn x -> x.name end)
    end

    defp get_rows(view, el_to_find) do
      view
      |> element("#opportunities")
      |> render()
      |> Floki.parse_fragment!()
      |> Floki.find(el_to_find)
      |> Enum.map(fn x -> Floki.text(x) |> String.trim() end)
    end
  end
end
