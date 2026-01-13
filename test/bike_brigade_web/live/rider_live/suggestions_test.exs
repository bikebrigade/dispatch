defmodule BikeBrigadeWeb.RiderLive.SuggestionsTest do
  use BikeBrigade.DataCase

  alias BikeBrigadeWeb.RiderLive.Index.Suggestions
  alias BikeBrigade.Riders.RiderSearch.Filter

  describe "weekday suggestions" do
    test "typing 'active:mon' suggests 'monday' and 'month'" do
      suggestions = Suggestions.suggest(%Suggestions{}, "active:mon")
      IO.inspect suggestions
      weekday_searches = Enum.map(suggestions.active, & &1.search)

      assert "monday" in weekday_searches
      assert "month" in weekday_searches
      refute "tuesday" in weekday_searches
    end

    test "typing 'active:tue' suggests 'tuesday'" do
      suggestions = Suggestions.suggest(%Suggestions{}, "active:tue")

      weekday_searches = Enum.map(suggestions.active, & &1.search)

      assert "tuesday" in weekday_searches
      assert length(weekday_searches) == 1
    end

    test "all weekdays are available in suggestions" do
      suggestions = Suggestions.suggest(%Suggestions{}, "active:")

      weekday_searches = Enum.map(suggestions.active, & &1.search)

      assert "monday" in weekday_searches
      assert "tuesday" in weekday_searches
      assert "wednesday" in weekday_searches
      assert "thursday" in weekday_searches
      assert "friday" in weekday_searches
      assert "saturday" in weekday_searches
      assert "sunday" in weekday_searches
    end

    test "weekday suggestions have correct Filter type" do
      suggestions = Suggestions.suggest(%Suggestions{}, "active:monday")

      assert [%Filter{type: :active, search: "monday"}] = suggestions.active
    end

    test "time period suggestions still work" do
      suggestions = Suggestions.suggest(%Suggestions{}, "active:hour")

      weekday_searches = Enum.map(suggestions.active, & &1.search)

      assert "hour" in weekday_searches
    end

  end
end
