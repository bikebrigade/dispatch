defmodule BikeBrigadeWeb.ItineraryLiveTest do
  use BikeBrigadeWeb.ConnCase

  alias BikeBrigade.Delivery
  alias BikeBrigade.LocalizedDateTime

  alias BikeBrigade.Repo.Seeds.Toronto

  import Phoenix.LiveViewTest

  describe "Itinerary for User without associated Rider" do
    setup [:login]

    test "Displays error when user has no rider", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/itinerary")

      assert html =~ "Itinerary"
      assert html =~ "User is not associated with a rider!"
    end
  end

  describe "Itinerary for User with associated Rider" do
    setup [:create_campaign, :login_as_rider]

    test "doesn't show an error", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/itinerary")

      assert html =~ "Itinerary"
      refute html =~ "User is not associated with a rider!"
    end

    test "shows days without campaigns", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/itinerary")

      assert html =~ "Itinerary"
      assert html =~ Calendar.strftime(LocalizedDateTime.today(), "%a %B %-d, %Y")
      assert html =~ "No campaigns found for this day."
    end

    test "can go to previous day", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/itinerary")

      assert html =~ "Itinerary"

      html =
        view
        |> element("[aria-label='Previous Day']")
        |> render_click()

      previous_day = Date.add(LocalizedDateTime.today(), -1)

      assert html =~ Calendar.strftime(previous_day, "%a %B %-d, %Y")
    end

    test "can go to next day", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/itinerary")

      assert html =~ "Itinerary"

      html =
        view
        |> element("[aria-label='Next Day']")
        |> render_click()

      next_day = Date.add(LocalizedDateTime.today(), 1)

      assert html =~ Calendar.strftime(next_day, "%a %B %-d, %Y")
    end

    test "displays itinerary with campaigns", %{
      conn: conn,
      rider: rider,
      campaign: campaign,
      program: program
    } do
      # TODO: make this a fixture
      # Add rider to campaign
      campaign_rider = create_campaign_rider_for_test(campaign, rider)

      # Create a task assigned to rider
      {_task, _dropoff_name, _item} = create_task_for_test(campaign, rider, program)

      {:ok, view, html} = live(conn, ~p"/itinerary")

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

  describe "Delivery status display" do
    setup [:create_campaign, :login_as_rider]

    test "displays Mark Complete button for unfinished tasks", %{
      conn: conn,
      rider: rider,
      campaign: campaign,
      program: program
    } do
      campaign_rider = create_campaign_rider_for_test(campaign, rider)

      {_task, dropoff_name, item} = create_task_for_test(campaign, rider, program)

      {:ok, view, html} = live(conn, ~p"/app/delivery/#{campaign_rider.token}")

      # Check that the specific delivery item is displayed
      assert html =~ dropoff_name
      assert html =~ "1 #{item.name}"

      # Check for Mark Complete button (rendered as a link element)
      assert has_element?(view, "a", "Mark Complete")
    end

    test "displays Completed label for completed tasks", %{
      conn: conn,
      rider: rider,
      campaign: campaign,
      program: program
    } do
      dropoff_name = Faker.Person.first_name()
      item = hd(program.items)

      campaign_rider = create_campaign_rider_for_test(campaign, rider)

      {:ok, _task} =
        Delivery.create_task_for_campaign(campaign, %{
          dropoff_name: dropoff_name,
          dropoff_location: Toronto.random_location(),
          task_items: [%{item_id: item.id, count: 1}],
          assigned_rider_id: rider.id,
          delivery_status: :completed
        })

      {:ok, view, html} = live(conn, ~p"/app/delivery/#{campaign_rider.token}")

      # Check that the specific delivery item is displayed
      assert html =~ dropoff_name
      assert html =~ "1 #{item.name}"

      # Check for Completed label in div element
      assert has_element?(view, "div", "Completed")

      # Verify Mark Complete button is NOT present
      refute has_element?(view, "a", "Mark Complete")
    end
  end

  # Helper function to create a campaign rider
  defp create_campaign_rider_for_test(campaign, rider) do
    {:ok, campaign_rider} =
      Delivery.create_campaign_rider(%{
        campaign_id: campaign.id,
        rider_id: rider.id
      })

    campaign_rider
  end

  # Helper function to create a task for testing
  defp create_task_for_test(campaign, rider, program, opts \\ []) do
    dropoff_name = Keyword.get(opts, :dropoff_name, Faker.Person.first_name())

    item = hd(program.items)

    task_attrs = %{
      dropoff_name: dropoff_name,
      dropoff_location: Toronto.random_location(),
      task_items: [%{item_id: item.id, count: 1}],
      assigned_rider_id: rider.id
    }

    {:ok, task} = Delivery.create_task_for_campaign(campaign, task_attrs)
    {task, dropoff_name, item}
  end
end
