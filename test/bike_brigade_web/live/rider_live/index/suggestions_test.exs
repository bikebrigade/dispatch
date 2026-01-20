defmodule BikeBrigadeWeb.RiderLive.Index.SuggestionsTest do
  use ExUnit.Case, async: true

  alias BikeBrigadeWeb.RiderLive.Index.Suggestions
  alias BikeBrigade.Riders.RiderSearch.Filter

  describe "weekday suggestions" do
    test "typing 'active:mon' suggests 'monday' and 'month'" do
      searches = suggestions_for("active:mon")

      assert Enum.all?(~w(monday month), &(&1 in searches))
      refute "tuesday" in searches
    end

    test "typing 'active:tue' suggests 'tuesday'" do
      searches = suggestions_for("active:tue")

      assert "tuesday" in searches
      assert length(searches) == 1
    end

    test "all weekdays are available in suggestions" do
      searches = suggestions_for("active:")

      assert Enum.all?(
               ~w(monday tuesday wednesday thursday friday saturday sunday),
               &(&1 in searches)
             )
    end

    test "weekday suggestions have correct Filter type" do
      suggestions = Suggestions.suggest(%Suggestions{}, "active:monday")

      assert [%Filter{type: :active, search: "monday"}] = suggestions.active
    end

    test "time period suggestions still work" do
      searches = suggestions_for("active:hour")

      assert "hour" in searches
    end
  end

  defp suggestions_for(input) do
    suggestions = Suggestions.suggest(%Suggestions{}, input)
    Enum.map(suggestions.active, & &1.search)
  end
end
