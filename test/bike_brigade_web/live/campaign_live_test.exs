defmodule BikeBrigadeWeb.CampaignLiveTest do
  use BikeBrigadeWeb.ConnCase, only: []

  import Phoenix.LiveViewTest
  alias BikeBrigadeWeb.CampaignHelpers
  alias BikeBrigade.LocalizedDateTime

  describe "Index" do
    setup [:create_campaign, :login]

    test "lists campaigns for week campaigns", %{conn: conn, program: program} do
      {:ok, _index_live, html} = live(conn, ~p"/campaigns/")

      assert html =~ "Campaigns"
      assert html =~ program.name
    end

    test "redirects to show campaign", %{conn: conn, campaign: campaign, program: program} do
      {:ok, view, _html} = live(conn, ~p"/campaigns/")

      view
      |> element("#campaign-#{campaign.id} a", "#{program.name}")
      |> render_click()

      assert_redirected(view, "/campaigns/#{campaign.id}")
    end

    test "clicking 'New Campaign' goes to new campaign route", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/campaigns/")
      view |> element("a", "New Campaign") |> render_click()
      assert_patched(view, ~p"/campaigns/new")
    end

    test "Can duplicate a campaign", ctx do
      # get current week for the query param.
      d = LocalizedDateTime.today() |> Date.beginning_of_week()
      week_str = Date.to_iso8601(d)

      {:ok, view, _html} = live(ctx.conn, ~p"/campaigns/")
      view |> element("#duplicate-campaign-#{ctx.campaign.id}") |> render_click()
      assert_patched(view, ~p"/campaigns/#{ctx.campaign}/duplicate")
      view |> element("#duplicate-campaign-form") |> render_submit()
      assert_redirected(view, ~p"/campaigns?current_week=#{week_str}")

      # Revisit with a fresh view and ensure we have duplicates
      {:ok, view, _html} = live(ctx.conn, ~p"/campaigns/")
      rendered = render(view)

      campaign_rows =
        Floki.parse_fragment!(rendered)
        |> Floki.find("[data-test-group=campaign-name]")
        |> Enum.map(fn x -> String.trim(Floki.text(x)) end)

      assert(Enum.uniq(campaign_rows) != campaign_rows)
    end

    test "Can delete a campaign", ctx do
      {:ok, view, html} = live(ctx.conn, ~p"/campaigns/")
      assert html =~ CampaignHelpers.name(ctx.campaign)
      html = view |> element("#campaign-#{ctx.campaign.id} a", "Delete") |> render_click()
      refute html =~ CampaignHelpers.name(ctx.campaign)
    end
  end

  describe "Show" do
    setup [:create_campaign, :create_rider, :login]

    test "displays campaign", %{conn: conn, campaign: campaign} do
      {:ok, _show_live, html} = live(conn, ~p"/campaigns/#{campaign}")

      assert html =~ campaign.program.name
    end

    test "can add a task", %{conn: conn, campaign: campaign} do
      {:ok, view, html} = live(conn, ~p"/campaigns/#{campaign}")

      refute html =~ "Recipient Mcgee"

      view
      |> element("a", "Add Task")
      |> render_click()

      {:ok, _view, html} =
        view
        |> form("#task_form",
          task: %{dropoff_name: "Recipient Mcgee", dropoff_location: %{address: "2758 Yonge St"}}
        )
        |> render_submit()
        # TODO: we should be patching here
        |> follow_redirect(conn)

      assert html =~ "Recipient Mcgee"
    end

    test "can add a rider", %{conn: conn, campaign: campaign, rider: rider} do
      {:ok, view, html} = live(conn, ~p"/campaigns/#{campaign}")

      refute html =~ rider.name

      # Click on add rider
      view
      |> element("a", "Add Rider")
      |> render_click()

      # Select rider
      view
      |> select_rider(rider)

      # Make sure we actually selected the rider
      assert has_element?(
               view,
               ~s|#add_rider_form_rider_id input[name="campaign_rider[rider_id]"][value="#{rider.id}"]|
             )

      {:ok, _view, html} =
        view
        |> form("#add_rider_form")
        |> render_submit()
        |> follow_redirect(conn)

      assert html =~ rider.name
    end
  end

  # Still a work in progress
  @tag :skip
  describe "New" do
    setup [:create_campaign, :login]

    test "create campaigns", %{conn: conn} do
      #  Process.flag(:trap_exit, true)
      {:ok, view, html} = live(conn, ~p"/campaigns/new")

      assert html =~ "New Campaign"

      deliveries =
        file_input(view, "form", :delivery_spreadsheet, [
          %{
            name: "deliveries.csv",
            content: """
            Visit Name,Street,Zip code,Phone,Notes,Buzzer and Unit,Partner,Box Type
            Mark C,1899 Queen St West,M6R 1A9,16475551922,Deliver to security; security will drop-off,123,ABC,Large box
            Sofia Q,924 College St,M6H 1A4,4165551234,,Buzz: 20 Unit 32,Large box
            """,
            type: "text/csv"
          }
        ])

      # Process.unlink(deliveries.pid)
      render_upload(deliveries, "deliveries.csv", 100)
      {_, _, proxy_pid} = view.proxy

      assert_receive {:EXIT, ^proxy_pid, {:shutdown, :closed}}

      deliveries =
        file_input(view, "form", :delivery_spreadsheet2, [
          %{
            name: "deliveries.csv",
            content: """
            Visit Name,Street,Zip code,Phone,Notes,Buzzer and Unit,Partner,Box Type
            Mark C,1899 Queen St West,M6R 1A9,16475551922,Deliver to security; security will drop-off,123,ABC,Large box
            Sofia Q,924 College St,M6H 1A4,4165551234,,Buzz: 20 Unit 32,Large box
            """,
            type: "text/csv"
          }
        ])

      render_upload(deliveries, "deliveries.csv", 100)
      {_, _, proxy_pid} = view.proxy

      assert_receive {:EXIT, ^proxy_pid, {:shutdown, :closed}}
    end
  end

  # Select a rider from the rider selection component
  defp select_rider(view, rider) do
    # Find a rider
    view
    |> element("#add_rider_form_rider_id input")
    |> render_keyup(%{value: rider.name})

    view
    |> element("#add_rider_form_rider_id a")
    |> render_click()

    view
  end
end
