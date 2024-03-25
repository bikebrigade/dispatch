defmodule BikeBrigadeWeb.RiderHomeLiveTest do
  use BikeBrigadeWeb.ConnCase, only: []
  alias BikeBrigade.LocalizedDateTime

  import Phoenix.LiveViewTest

  describe "Rider Home Screen" do
    setup ctx do
      program = fixture(:program, %{name: "ACME Delivery"})
      res = login_as_rider(ctx)
      Map.merge(res, %{program: program})
    end

    test "it shows am empty state, copy, cta button, when rider has no itinerary", ctx do
      {:ok, live, html} = live(ctx.conn, ~p"/home")
      assert html =~ "You do not have any deliveries today."
      assert html =~ "/images/cyclist-empty-state.svg"
      assert html =~ "no-campaigns-signup-btn"
    end

    test "it shows a call to action for campaigns that need riders TODAY; goes to correct view", ctx do
      program = fixture(:program, %{name: "ABC Foodbank"})

      campaign =
        fixture(:campaign, %{
          program_id: ctx.program.id,
          delivery_start: LocalizedDateTime.now(),
          delivery_end: LocalizedDateTime.now() |> DateTime.add(1, :hour)
        })

      campaign2 =
        fixture(:campaign, %{
          program_id: program.id,
          delivery_start: LocalizedDateTime.now(),
          delivery_end: LocalizedDateTime.now() |> DateTime.add(1, :hour)
        })

      campaign3 =
        fixture(:campaign, %{
          program_id: program.id,
          delivery_start: LocalizedDateTime.now() |> DateTime.add(1, :day),
          delivery_end: LocalizedDateTime.now() |> DateTime.add(1, :day) |> DateTime.add(1, :hour)
        })

      fixture(:task, %{campaign: campaign, rider: nil})
      fixture(:task, %{campaign: campaign, rider: nil})
      fixture(:task, %{campaign: campaign2, rider: nil})
      fixture(:task, %{campaign: campaign3, rider: nil})

      {:ok, live, html} = live(ctx.conn, ~p"/home")
      assert html =~ "4 Unassigned deliveries"
      assert html =~ "ACME Delivery and ABC Foodbank are looking for riders for the next 48 hours."

      live
      |> element("#urgent-campaigns-signup-btn")
      |> render_click()

      expected_redirect = ~p"/campaigns/signup?campaign_ids[]=#{campaign.id}&campaign_ids[]=#{campaign2.id}&campaign_ids[]=#{campaign3.id}"
      assert_redirected(live, expected_redirect)

      {:ok, live, html} = live(ctx.conn, expected_redirect)

      assert live |> has_element?("#campaign-#{campaign.id}")
      assert live |> has_element?("#campaign-#{campaign2.id}")

      # assert that only 2 campaigns - the ones with unfilled tasks are showing up.
      assert Floki.parse_document!(html)
      |> Floki.find(".campaign-item")
      |> Enum.count()  == 3
    end

    test "it shows the riders itinerary when they have deliveries for today, with a sign up button",
         ctx do
      program = fixture(:program, %{name: "ABC Foodbank"})

      campaign =
        fixture(:campaign, %{
          program_id: ctx.program.id,
          delivery_start: LocalizedDateTime.now(),
          delivery_end: LocalizedDateTime.now() |> DateTime.add(1, :hour)
        })

      campaign2 =
        fixture(:campaign, %{
          program_id: program.id,
          delivery_start: LocalizedDateTime.now(),
          delivery_end: LocalizedDateTime.now() |> DateTime.add(1, :hour)
        })

      fixture(:task, %{campaign: campaign, rider: ctx.rider})
      fixture(:task, %{campaign: campaign2, rider: ctx.rider})

      {:ok, _live, html} = live(ctx.conn, ~p"/home")
      assert html =~ "ACME Delivery"
      assert html =~ "ABC Foodbank"
    end

    test "it shows a stats based on the last seven days", ctx do
      program = fixture(:program, %{name: "ABC Foodbank"})
      rider_2 = fixture(:rider, %{name: "Hannah Bannana"})

      campaign =
        fixture(:campaign, %{
          program_id: ctx.program.id,
          delivery_start: LocalizedDateTime.now() |> DateTime.add(-7, :day),
          delivery_end:
            LocalizedDateTime.now() |> DateTime.add(-7, :day) |> DateTime.add(60, :second)
        })

      campaign2 =
        fixture(:campaign, %{
          program_id: program.id,
          delivery_start: LocalizedDateTime.now() |> DateTime.add(-7, :day),
          delivery_end:
            LocalizedDateTime.now() |> DateTime.add(-7, :day) |> DateTime.add(60, :second)
        })

      for _r <- 1..7, do: fixture(:task, %{campaign: campaign, rider: ctx.rider})
      fixture(:task, %{campaign: campaign2, rider: rider_2})

      {:ok, _live, html} = live(ctx.conn, ~p"/home")

      floki_output =
        html
        |> Floki.parse_fragment!()
        |> Floki.find("#week-stats")
        |> Floki.text()

      # Our HTML is full of empty space and newlines when Floki parses the text
      # (probably all the spans?) It's easier to just test the exactly output of
      # floki rather than munge it into what the dom looks like.
      # Also, note that we don't test the full string, because the test data
      # results in variable kilometer distance.
      assert floki_output =~ "2 riders\n    have delivered 8 items\n    for 2 programs,\n   "
    end
  end
end
