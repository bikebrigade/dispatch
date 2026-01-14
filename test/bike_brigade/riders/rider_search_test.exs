defmodule BikeBrigade.Riders.RiderSearchTest do
  use BikeBrigade.DataCase

  alias BikeBrigade.Delivery
  alias BikeBrigade.Riders.RiderSearch
  alias BikeBrigade.Riders.RiderSearch.Filter

  describe "weekday filtering" do
    setup do
      rider_monday = fixture(:rider, %{name: "Monday Rider"})
      rider_none = fixture(:rider, %{name: "No Campaign Rider"})

      today = Date.utc_today()

      days_since_monday = Date.day_of_week(today) - 1
      monday_date = Date.add(today, -days_since_monday)

      monday_datetime = DateTime.new!(monday_date, ~T[12:00:00], "Etc/UTC")
      campaign_monday = fixture(:campaign, %{delivery_start: monday_datetime})

      Delivery.create_campaign_rider(%{
        campaign_id: campaign_monday.id,
        rider_id: rider_monday.id
      })

      %{
        rider_monday: rider_monday,
        rider_none: rider_none,
        monday_date: monday_date
      }
    end

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
  end
end
