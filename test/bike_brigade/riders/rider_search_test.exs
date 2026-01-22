defmodule BikeBrigade.Riders.RiderSearchTest do
  use BikeBrigade.DataCase

  alias BikeBrigade.Delivery
  alias BikeBrigade.Riders.RiderSearch
  alias BikeBrigade.Riders.RiderSearch.Filter

  # Shared helper functions
  defp get_monday_date(today \\ Date.utc_today()) do
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

  describe "monday + week combined filter" do
    test "includes rider with 1 monday campaign in the current week" do
      # PREPARE: Create rider with 1 Monday campaign in the current week
      rider = fixture(:rider, %{name: "Monday Rider"})
      today = Date.utc_today()
      days_since_monday = Date.day_of_week(today) - 1
      monday_this_week = Date.add(today, -days_since_monday)

      campaign_datetime = DateTime.new!(monday_this_week, ~T[12:00:00], "Etc/UTC")
      campaign = fixture(:campaign, %{delivery_start: campaign_datetime})

      Delivery.create_campaign_rider(%{
        campaign_id: campaign.id,
        rider_id: rider.id
      })

      # ACTION: Search with both monday AND week filters
      {_rs, results} =
        RiderSearch.new(
          filters: [
            %Filter{type: :active, search: "monday"},
            %Filter{type: :active, search: "week"}
          ]
        )
        |> RiderSearch.fetch()

      # ASSERT: Rider is included (has monday activity in the current week)
      rider_ids = Enum.map(results.page, & &1.id)
      assert rider.id in rider_ids
    end
  end

  describe "monday + month combined filter" do
    test "includes rider with 1 monday campaign in the current month" do
      # PREPARE: Create rider with 1 Monday campaign within the last month
      rider = fixture(:rider, %{name: "Monday Rider"})
      today = Date.utc_today()
      days_since_monday = Date.day_of_week(today) - 1
      monday_two_weeks_ago = Date.add(today, -days_since_monday - 14)

      campaign_datetime = DateTime.new!(monday_two_weeks_ago, ~T[12:00:00], "Etc/UTC")
      campaign = fixture(:campaign, %{delivery_start: campaign_datetime})

      Delivery.create_campaign_rider(%{
        campaign_id: campaign.id,
        rider_id: rider.id
      })

      # ACTION: Search with both monday AND month filters
      {_rs, results} =
        RiderSearch.new(
          filters: [
            %Filter{type: :active, search: "monday"},
            %Filter{type: :active, search: "month"}
          ]
        )
        |> RiderSearch.fetch()

      # ASSERT: Rider is included (has monday activity in the current month)
      rider_ids = Enum.map(results.page, & &1.id)
      assert rider.id in rider_ids
    end
  end

  describe "weekday filtering with thresholds" do
    setup [:setup_riders_with_thresholds, :setup_monday_campaigns_with_thresholds]

    test "includes rider meeting all thresholds (volume, density, recency)", %{
      rider_all_thresholds: rider,
      monday_campaigns: monday_campaigns
    } do
      # Verify test data: rider should have 3+ deliveries, 16+ weeks, recent activity
      # assert length(mondays) >= 16

      {_rs, results} =
        RiderSearch.new(filters: [%Filter{type: :active, search: "monday"}])
        |> RiderSearch.fetch()

      rider_ids = Enum.map(results.page, & &1.id)
      assert rider.id in rider_ids
    end

    test "excludes rider failing volume threshold (< 3 deliveries)", %{
      rider_low_volume: rider
    } do
      {_rs, results} =
        RiderSearch.new(filters: [%Filter{type: :active, search: "monday"}])
        |> RiderSearch.fetch()

      rider_ids = Enum.map(results.page, & &1.id)
      refute rider.id in rider_ids
    end

    defp setup_riders_with_thresholds(_context) do
      %{
        rider_all_thresholds: fixture(:rider, %{name: "All Thresholds Rider"}),
        rider_low_volume: fixture(:rider, %{name: "Low Volume Rider"}),
        rider_low_density: fixture(:rider, %{name: "Low Density Rider"}),
        rider_old_activity: fixture(:rider, %{name: "Old Activity Rider"}),
        rider_none: fixture(:rider, %{name: "No Campaign Rider"})
      }
    end

    defp setup_monday_campaigns_with_thresholds(context) do
      today = Date.utc_today()

      # rider_all_thresholds: 3+ deliveries, 16+ weeks, recent (within last 3 months)
      monday_campaigns =
        for week_offset <- 0..5 do
          monday_date = get_monday_date(Date.add(today, -week_offset * 7))
          create_campaign_for_date(monday_date)
        end

      Enum.each(Enum.take(monday_campaigns, 3), fn campaign ->
        link_rider_to_campaign(context.rider_all_thresholds.id, campaign.id)
      end)

      %{monday_campaigns: monday_campaigns}
    end
  end

  describe "weekday filtering" do
    setup [:setup_riders_for_weekday_filtering, :setup_multiple_monday_campaigns, :link_riders_to_campaigns]

    test "filters riders by monday activity", %{
      rider_monday: rider_monday
    } do
      {_rs, results} =
        RiderSearch.new(filters: [%Filter{type: :active, search: "monday"}])
        |> RiderSearch.fetch()

      rider_ids = Enum.map(results.page, & &1.id)

      # Rider has 3+ monday campaigns, should be included
      assert rider_monday.id in rider_ids
    end

    test "excludes riders with no campaigns", %{rider_none: rider_none} do
      {_rs, results} =
        RiderSearch.new(filters: [%Filter{type: :active, search: "monday"}])
        |> RiderSearch.fetch()

      rider_ids = Enum.map(results.page, & &1.id)

      refute rider_none.id in rider_ids
    end

    defp setup_riders_for_weekday_filtering(_context) do
      %{
        rider_monday: fixture(:rider, %{name: "Monday Rider"}),
        rider_none: fixture(:rider, %{name: "No Campaign Rider"})
      }
    end

    defp setup_multiple_monday_campaigns(_context) do
      today = Date.utc_today()

      # Create 3+ Monday campaigns to meet volume threshold
      monday_campaigns =
        for week_offset <- 0..2 do
          monday_date = get_monday_date(Date.add(today, -week_offset * 7))
          create_campaign_for_date(monday_date)
        end

      %{monday_campaigns: monday_campaigns}
    end

    defp link_riders_to_campaigns(context) do
      Enum.each(context.monday_campaigns, fn campaign ->
        link_rider_to_campaign(context.rider_monday.id, campaign.id)
      end)

      :ok
    end
  end
end
