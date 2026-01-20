defmodule BikeBrigade.Riders.RiderSearchTest do
  use BikeBrigade.DataCase

  alias BikeBrigade.Delivery
  alias BikeBrigade.Riders.RiderSearch
  alias BikeBrigade.Riders.RiderSearch.Filter

  describe "weekday filtering" do
    setup [:setup_riders, :setup_monday_campaign, :link_riders_to_campaigns]

    test "filters riders by monday activity", %{
      rider_monday: rider_monday,
      monday_date: monday_date
    } do
      assert Date.day_of_week(monday_date) == 1

      {_rs, results} =
        RiderSearch.new(filters: [%Filter{type: :active, search: "monday"}])
        |> RiderSearch.fetch()

      rider_ids = Enum.map(results.page, & &1.id)

      assert rider_monday.id in rider_ids
    end

    test "excludes riders with no campaigns", %{rider_none: rider_none} do
      {_rs, results} =
        RiderSearch.new(filters: [%Filter{type: :active, search: "monday"}])
        |> RiderSearch.fetch()

      rider_ids = Enum.map(results.page, & &1.id)

      refute rider_none.id in rider_ids
    end

    defp get_monday_date do
      today = Date.utc_today()
      days_since_monday = Date.day_of_week(today) - 1
      Date.add(today, -days_since_monday)
    end

    defp create_campaign_for_date(date) do
      datetime = DateTime.new!(date, ~T[12:00:00], "Etc/UTC")
      fixture(:campaign, %{delivery_start: datetime})
    end

    defp link_rider_to_campaign(rider_id, campaign_id) do
      Delivery.create_campaign_rider(%{
        campaign_id: campaign_id,
        rider_id: rider_id
      })
    end

    defp setup_riders(_context) do
      %{
        rider_monday: fixture(:rider, %{name: "Monday Rider"}),
        rider_none: fixture(:rider, %{name: "No Campaign Rider"})
      }
    end

    defp setup_monday_campaign(_context) do
      monday_date = get_monday_date()
      campaign_monday = create_campaign_for_date(monday_date)

      %{
        monday_date: monday_date,
        campaign_monday: campaign_monday
      }
    end

    defp link_riders_to_campaigns(context) do
      link_rider_to_campaign(context.rider_monday.id, context.campaign_monday.id)
      :ok
    end
  end
end
