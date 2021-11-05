defmodule BikeBrigadeWeb.CampaignLiveTest do
  use BikeBrigadeWeb.ConnCase, only: []

  import Phoenix.LiveViewTest

  describe "Index" do
    setup [:create_campaign, :login]

    test "lists campaigns for week campaigns", %{conn: conn, campaign: campaign} do
      {:ok, _index_live, html} = live(conn, Routes.campaign_index_path(conn, :index))

      assert html =~ "Campaigns"
      assert html =~ campaign.name
    end

    test "redirects to show campaign", %{conn: conn, campaign: campaign} do
      {:ok, view, _html} = live(conn, Routes.campaign_index_path(conn, :index))

      view
      |> element("##{campaign.id} a", "#{campaign.name}")
      |> render_click()

      assert_redirected(view, "/campaigns/#{campaign.id}")
    end
  end

  describe "Show" do
    setup [:create_campaign, :login]

    test "displays campaign", %{conn: conn, campaign: campaign} do
      {:ok, _show_live, html} = live(conn, Routes.campaign_show_path(conn, :show, campaign))

      assert html =~ campaign.name
    end
  end

  # Still a work in progress
  @tag :skip
  describe "New" do
    setup [:create_campaign, :login]

    test "create campaigns", %{conn: conn, campaign: campaign} do
    #  Process.flag(:trap_exit, true)
      {:ok, view, html} = live(conn, Routes.campaign_new_path(conn, :new))

      assert html =~ "New Campaign"

      deliveries = file_input(view, "form", :delivery_spreadsheet, [%{
        name: "deliveries.csv",
        content: """
        Visit Name,Street,Zip code,Phone,Notes,Buzzer and Unit,Partner,Box Type
        Mark C,1899 Queen St West,M6R 1A9,16475551922,Deliver to security; security will drop-off,123,ABC,Large box
        Sofia Q,924 College St,M6H 1A4,4165551234,,Buzz: 20 Unit 32,Large box
        """,
        type: "text/csv"
      }])

      IO.inspect deliveries.pid
      IO.inspect view.pid
      IO.inspect Phoenix.LiveViewTest.UploadClient.channel_pids(deliveries)


#Process.unlink(deliveries.pid)
   render_upload(deliveries, "deliveries.csv",100)
    {_,_,proxy_pid} = view.proxy


   IO.inspect(proxy_pid)

     assert_receive {:EXIT, proxy_pid, {:shutdown, :closed}}
    # require IEx; IEx.pry
      # view
      #|> open_browser()

      deliveries = file_input(view, "form", :delivery_spreadsheet2, [%{
        name: "deliveries.csv",
        content: """
        Visit Name,Street,Zip code,Phone,Notes,Buzzer and Unit,Partner,Box Type
        Mark C,1899 Queen St West,M6R 1A9,16475551922,Deliver to security; security will drop-off,123,ABC,Large box
        Sofia Q,924 College St,M6H 1A4,4165551234,,Buzz: 20 Unit 32,Large box
        """,
        type: "text/csv"
      }])

      render_upload(deliveries, "deliveries.csv",100)
      require IEx; IEx.pry
      {_,_,proxy_pid} = view.proxy

      IO.inspect(proxy_pid)
      assert_receive {:EXIT, ^proxy_pid, {:shutdown, :closed}}
    end
  end
end
