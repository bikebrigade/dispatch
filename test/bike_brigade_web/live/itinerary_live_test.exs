defmodule BikeBrigadeWeb.ItineraryLiveTest do
  use BikeBrigadeWeb.ConnCase

  alias BikeBrigade.Delivery
  alias BikeBrigade.LocalizedDateTime

  alias BikeBrigade.Repo.Seeds.Toronto

  import Phoenix.LiveViewTest

  describe "Itinerary for User without associated Rider" do
    setup [:login]

    test "Displays error when user has no rider", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, Routes.itinerary_index_path(conn, :index))

      assert html =~ "Itinerary"
      assert html =~ "User is not associated with a rider!"
    end
  end

  describe "Itinerary for User with associated Rider" do
    setup [:create_campaign, :login_as_rider]

    test "doesn't show an error", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, Routes.itinerary_index_path(conn, :index))

      assert html =~ "Itinerary"
      refute html =~ "User is not associated with a rider!"
    end

    test "shows days without campaigns", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, Routes.itinerary_index_path(conn, :index))

      assert html =~ "Itinerary"
      assert html =~ Calendar.strftime(LocalizedDateTime.today(), "%A %B %-d, %Y")
      assert html =~ "No campaigns found for this day."
    end

    test "can go to previous day", %{conn: conn} do
      {:ok, view, html} = live(conn, Routes.itinerary_index_path(conn, :index))

      assert html =~ "Itinerary"

      html =
        view
        |> element("[aria-label='Previous Day']")
        |> render_click()

      previous_day = Date.add(LocalizedDateTime.today(), -1)

      assert html =~ Calendar.strftime(previous_day, "%A %B %-d, %Y")
    end

    test "can go to next day", %{conn: conn} do
      {:ok, view, html} = live(conn, Routes.itinerary_index_path(conn, :index))

      assert html =~ "Itinerary"

      html =
        view
        |> element("[aria-label='Next Day']")
        |> render_click()

      next_day = Date.add(LocalizedDateTime.today(), 1)

      assert html =~ Calendar.strftime(next_day, "%A %B %-d, %Y")
    end

    test "displays itinerary with campaigns", %{
      conn: conn,
      rider: rider,
      campaign: campaign,
      program: program
    } do
      # TODO: make this a fixture
      # Add rider to campaign
      {:ok, campaign_rider} =
        Delivery.create_campaign_rider(%{
          campaign_id: campaign.id,
          rider_id: rider.id
        })

      # Create a task assigned to rider
      {:ok, _task} =
        Delivery.create_task_for_campaign(campaign, %{
          dropoff_name: Faker.Person.first_name(),
          dropoff_location: Toronto.random_location(),
          task_items: [%{item_id: hd(program.items).id, count: 1}],
          assigned_rider_id: rider.id
        })

      {:ok, view, html} = live(conn, Routes.itinerary_index_path(conn, :index))

      assert html =~ program.name
      assert html =~ "1 #{hd(program.items).name}"

      # redirect to delivery details page
      {:ok, _view, _html} =
        view
        |> element("a", "Details")
        |> render_click()
        |> follow_redirect(conn, "/app/delivery/#{campaign_rider.token}")
    end
  end
end
