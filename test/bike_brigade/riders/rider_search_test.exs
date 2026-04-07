defmodule BikeBrigade.Riders.RiderSearchTest do
  use BikeBrigade.DataCase, async: true

  alias BikeBrigade.Delivery
  alias BikeBrigade.Riders.RiderSearch
  alias BikeBrigade.Riders.RiderSearch.Filter

  describe "monday + week combined filter" do
    test "includes rider with 1 monday campaign in the current week" do
      rider = fixture(:rider, %{name: "Rider"})
      create_and_link_monday_campaign(rider.id)

      {_rs, results} =
        RiderSearch.new(
          filters: [
            %Filter{type: :active, search: "monday"},
            %Filter{type: :active, search: "week"}
          ]
        )
        |> RiderSearch.fetch()

      assert rider_in_results?(results, rider.id)
    end

    test "excludes rider with monday campaign outside the current week" do
      rider = fixture(:rider, %{name: "Rider"})
      create_and_link_monday_campaign(rider.id, weeks_ago: 2)

      {_rs, results} =
        RiderSearch.new(
          filters: [
            %Filter{type: :active, search: "monday"},
            %Filter{type: :active, search: "week"}
          ]
        )
        |> RiderSearch.fetch()

      refute rider_in_results?(results, rider.id)
    end
  end

  describe "monday + month combined filter" do
    test "includes rider with 1 monday campaign in the current month" do
      rider = fixture(:rider, %{name: "Rider"})
      create_and_link_monday_campaign(rider.id, weeks_ago: 2)

      {_rs, results} =
        RiderSearch.new(
          filters: [
            %Filter{type: :active, search: "monday"},
            %Filter{type: :active, search: "month"}
          ]
        )
        |> RiderSearch.fetch()

      assert rider_in_results?(results, rider.id)
    end
  end

  describe "weekday filtering with thresholds" do
    setup [:setup_riders_with_thresholds, :setup_campaigns_with_thresholds]

    test "includes rider meeting all thresholds (volume, density, recency)", %{
      rider_all_thresholds: rider
    } do
      {_rs, results} =
        RiderSearch.new(filters: [%Filter{type: :active, search: "monday"}])
        |> RiderSearch.fetch()

      assert rider_in_results?(results, rider.id)
    end

    test "excludes rider failing volume threshold (< 3 deliveries)", %{
      rider_low_volume: rider
    } do
      {_rs, results} =
        RiderSearch.new(filters: [%Filter{type: :active, search: "monday"}])
        |> RiderSearch.fetch()

      refute rider_in_results?(results, rider.id)
    end

    test "excludes riders with no campaigns", %{rider_none: rider_none} do
      {_rs, results} =
        RiderSearch.new(filters: [%Filter{type: :active, search: "monday"}])
        |> RiderSearch.fetch()

      refute rider_in_results?(results, rider_none.id)
    end
  end

  defp setup_riders_with_thresholds(_context) do
    %{
      rider_all_thresholds: fixture(:rider, %{name: "All Thresholds Rider"}),
      rider_low_volume: fixture(:rider, %{name: "Low Volume Rider"}),
      rider_none: fixture(:rider, %{name: "No Campaign Rider"})
    }
  end

  defp setup_campaigns_with_thresholds(context) do
    monday_campaigns =
      for week_offset <- 0..5 do
        monday_date =
          DateTime.utc_now()
          |> DateTime.shift_zone!("America/Toronto")
          |> DateTime.to_date()
          |> Date.add(-week_offset * 7)
          |> get_monday_date()
          |> safe_past_monday()

        create_campaign_for_date(monday_date)
      end

    # rider_all_thresholds: 3 campaigns (meets ≥3 threshold)
    Enum.each(Enum.take(monday_campaigns, 3), fn campaign ->
      link_rider_to_campaign(context.rider_all_thresholds.id, campaign.id)
    end)

    # rider_low_volume: 2 campaigns (fails <3 threshold)
    Enum.each(Enum.take(monday_campaigns, 2), fn campaign ->
      link_rider_to_campaign(context.rider_low_volume.id, campaign.id)
    end)

    %{monday_campaigns: monday_campaigns}
  end

  defp get_monday_date(date) do
    days_since_monday = Date.day_of_week(date) - 1
    Date.add(date, -days_since_monday)
  end

  defp create_campaign_for_date(date) do
    # Use noon Toronto time so the campaign is correctly identified as that
    # day in Toronto timezone (what the monday filter checks via ISODOW).
    datetime =
      DateTime.new!(date, ~T[12:00:00], "America/Toronto")
      |> DateTime.shift_zone!("Etc/UTC")

    fixture(:campaign, %{delivery_start: datetime})
  end

  # If noon Toronto on monday_date is still in the future, use the previous
  # week's Monday. That Monday is 6 days 12+ hours ago, safely within
  # `ago(1, "week")` (7 days) and definitely past the `delivery_start < NOW()`
  # constraint in the riders_latest_campaigns view.
  defp safe_past_monday(monday_date) do
    candidate = DateTime.new!(monday_date, ~T[12:00:00], "America/Toronto")

    if DateTime.compare(candidate, DateTime.utc_now()) == :gt do
      Date.add(monday_date, -7)
    else
      monday_date
    end
  end

  defp link_rider_to_campaign(rider_id, campaign_id) do
    Delivery.create_campaign_rider(%{
      campaign_id: campaign_id,
      rider_id: rider_id
    })
  end

  defp create_and_link_monday_campaign(rider_id, opts \\ []) do
    weeks_ago = Keyword.get(opts, :weeks_ago, 0)

    campaign =
      DateTime.utc_now()
      |> DateTime.shift_zone!("America/Toronto")
      |> DateTime.to_date()
      |> Date.add(-weeks_ago * 7)
      |> get_monday_date()
      |> safe_past_monday()
      |> create_campaign_for_date()

    link_rider_to_campaign(rider_id, campaign.id)
  end

  defp rider_in_results?(results, id) do
    Enum.find(results.page, &(&1.id == id))
  end
end
