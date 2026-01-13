defmodule BikeBrigade.Riders.RiderSearchTest do
  use BikeBrigade.DataCase

  alias BikeBrigade.Delivery
  alias BikeBrigade.Riders.RiderSearch
  alias BikeBrigade.Riders.RiderSearch.Filter

  describe "weekday filtering" do
    setup do
      # Create riders
      rider_monday = fixture(:rider, %{name: "Monday Rider"})
      rider_tuesday = fixture(:rider, %{name: "Tuesday Rider"})
      rider_both = fixture(:rider, %{name: "Both Days Rider"})
      rider_old = fixture(:rider, %{name: "Old Campaign Rider"})
      rider_none = fixture(:rider, %{name: "No Campaign Rider"})

      # Calculate dates for specific weekdays within last 7 days
      today = Date.utc_today()

      # Find the most recent Monday (within last 7 days)
      days_since_monday = Date.day_of_week(today) - 1
      monday_date = Date.add(today, -days_since_monday)

      # Find the most recent Tuesday
      days_since_tuesday = rem(Date.day_of_week(today) - 2 + 7, 7)
      days_since_tuesday = if days_since_tuesday == 0 and Date.day_of_week(today) != 2, do: 7, else: days_since_tuesday
      tuesday_date = Date.add(today, -days_since_tuesday)

      # Create campaign on Monday
      monday_datetime = DateTime.new!(monday_date, ~T[12:00:00], "Etc/UTC")
      campaign_monday = fixture(:campaign, %{delivery_start: monday_datetime})

      # Create campaign on Tuesday
      tuesday_datetime = DateTime.new!(tuesday_date, ~T[12:00:00], "Etc/UTC")
      campaign_tuesday = fixture(:campaign, %{delivery_start: tuesday_datetime})

      # Create old campaign (8+ days ago)
      old_date = Date.add(today, -10)
      old_datetime = DateTime.new!(old_date, ~T[12:00:00], "Etc/UTC")
      campaign_old = fixture(:campaign, %{delivery_start: old_datetime})

      # Associate riders with campaigns
      Delivery.create_campaign_rider(%{campaign_id: campaign_monday.id, rider_id: rider_monday.id})
      Delivery.create_campaign_rider(%{campaign_id: campaign_tuesday.id, rider_id: rider_tuesday.id})

      # rider_both has campaigns on both days
      Delivery.create_campaign_rider(%{campaign_id: campaign_monday.id, rider_id: rider_both.id})
      Delivery.create_campaign_rider(%{campaign_id: campaign_tuesday.id, rider_id: rider_both.id})

      # rider_old only has old campaign
      Delivery.create_campaign_rider(%{campaign_id: campaign_old.id, rider_id: rider_old.id})

      %{
        rider_monday: rider_monday,
        rider_tuesday: rider_tuesday,
        rider_both: rider_both,
        rider_old: rider_old,
        rider_none: rider_none,
        monday_date: monday_date,
        tuesday_date: tuesday_date
      }
    end

    test "filters riders by monday activity", %{
      rider_monday: rider_monday,
      rider_both: rider_both,
      monday_date: monday_date
    } do
      # Verify our Monday date is actually a Monday
      assert Date.day_of_week(monday_date) == 1

      {_rs, results} =
        RiderSearch.new(filters: [%Filter{type: :active, search: "monday"}])
        |> RiderSearch.fetch()

      rider_ids = Enum.map(results.page, & &1.id)

      assert rider_monday.id in rider_ids
      assert rider_both.id in rider_ids
    end

    test "filters riders by tuesday activity", %{
      rider_tuesday: rider_tuesday,
      rider_both: rider_both,
      tuesday_date: tuesday_date
    } do
      # Verify our Tuesday date is actually a Tuesday
      assert Date.day_of_week(tuesday_date) == 2

      {_rs, results} =
        RiderSearch.new(filters: [%Filter{type: :active, search: "tuesday"}])
        |> RiderSearch.fetch()

      rider_ids = Enum.map(results.page, & &1.id)

      assert rider_tuesday.id in rider_ids
      assert rider_both.id in rider_ids
    end

    test "rider with multiple campaigns appears in both weekday searches", %{
      rider_both: rider_both
    } do
      {_rs, monday_results} =
        RiderSearch.new(filters: [%Filter{type: :active, search: "monday"}])
        |> RiderSearch.fetch()

      {_rs, tuesday_results} =
        RiderSearch.new(filters: [%Filter{type: :active, search: "tuesday"}])
        |> RiderSearch.fetch()

      monday_ids = Enum.map(monday_results.page, & &1.id)
      tuesday_ids = Enum.map(tuesday_results.page, & &1.id)

      assert rider_both.id in monday_ids
      assert rider_both.id in tuesday_ids
    end

    test "excludes riders with campaigns older than 7 days", %{
      rider_old: rider_old,
      monday_date: monday_date
    } do
      # Only run this test if Monday is within 7 days
      # (to ensure we have valid test data)
      days_ago = Date.diff(Date.utc_today(), monday_date)

      if days_ago <= 7 do
        {_rs, results} =
          RiderSearch.new(filters: [%Filter{type: :active, search: "monday"}])
          |> RiderSearch.fetch()

        rider_ids = Enum.map(results.page, & &1.id)

        refute rider_old.id in rider_ids
      end
    end

    test "excludes riders with no campaigns", %{rider_none: rider_none} do
      {_rs, results} =
        RiderSearch.new(filters: [%Filter{type: :active, search: "monday"}])
        |> RiderSearch.fetch()

      rider_ids = Enum.map(results.page, & &1.id)

      refute rider_none.id in rider_ids
    end

    test "excludes riders active on different weekday", %{
      rider_monday: rider_monday,
      rider_tuesday: rider_tuesday
    } do
      # Monday rider should not appear in Tuesday search
      {_rs, tuesday_results} =
        RiderSearch.new(filters: [%Filter{type: :active, search: "tuesday"}])
        |> RiderSearch.fetch()

      tuesday_ids = Enum.map(tuesday_results.page, & &1.id)
      refute rider_monday.id in tuesday_ids

      # Tuesday rider should not appear in Monday search
      {_rs, monday_results} =
        RiderSearch.new(filters: [%Filter{type: :active, search: "monday"}])
        |> RiderSearch.fetch()

      monday_ids = Enum.map(monday_results.page, & &1.id)
      refute rider_tuesday.id in monday_ids
    end
  end

  describe "weekday filtering - all days" do
    test "filters work for all weekdays" do
      weekdays = ~w(monday tuesday wednesday thursday friday saturday sunday)

      for {weekday, day_number} <- Enum.with_index(weekdays, 1) do
        # Create a rider and campaign for this weekday
        rider = fixture(:rider, %{name: "#{String.capitalize(weekday)} Rider"})

        # Calculate date for this weekday within last 7 days
        today = Date.utc_today()
        today_dow = Date.day_of_week(today)
        days_back = rem(today_dow - day_number + 7, 7)
        days_back = if days_back == 0 and today_dow != day_number, do: 7, else: days_back
        target_date = Date.add(today, -days_back)

        # Verify we got the right day
        assert Date.day_of_week(target_date) == day_number,
               "Expected #{weekday} (#{day_number}), got #{Date.day_of_week(target_date)}"

        # Create campaign on target date
        target_datetime = DateTime.new!(target_date, ~T[12:00:00], "Etc/UTC")
        campaign = fixture(:campaign, %{delivery_start: target_datetime})

        # Associate rider with campaign
        Delivery.create_campaign_rider(%{campaign_id: campaign.id, rider_id: rider.id})

        # Search for riders active on this weekday
        {_rs, results} =
          RiderSearch.new(filters: [%Filter{type: :active, search: weekday}])
          |> RiderSearch.fetch()

        rider_ids = Enum.map(results.page, & &1.id)

        assert rider.id in rider_ids,
               "Rider should appear in #{weekday} search"
      end
    end
  end
end
