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
  end
end
