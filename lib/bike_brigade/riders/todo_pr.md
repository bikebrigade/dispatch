TODO

Prepare
Act
Assert

** TODO Find active users in a month based on the given day

   Given there is a rider
   And the rider was active on the first monday of the month
   And it is the last monday of the month
   When I search for `active:month` and `active:monday`
   Then I see the rider in the results
   ===
   Given there is a rider
   And the rider was active every day except mondays of the month
   When I search for `active:month` and `active:monday`
   Then the rider does not appear in the results

** TODO Find active users in a week based on the given day

    Given there is a rider
    And the rider was active last tuesday of the week
    When I search for `active:week` and `active:tuesday`
    Then I see the rider in the results

    

Prepare - Action - Assert

Given there is a rider
And that rider worked a Monday in the last month
And was not active last week
When I search for `active:monday` and `active:week`
Then the rider does NOT appear in the results

Given there is a rider
And that rider worked a Monday in the last month
And was not active last week
When I search for `active:monday`
Then the rider appears in the results

Given there is a rider
And that rider worked a Monday 2 months ago
When I search for `active:monday` 
Then the rider does NOT appear in the results

# default pairing - this feels strange to me (below here)
# Auto adding month filter for active weekdays
Given I am a user
And an empty search filter set
When I add `active:monday` to the search filter
Then `active:month` also appears in the filters too

# Auto switch week and month filter (interesting, but not related to weekday filter)
# This makes these filters behave differently which might be confusing to the user
# active week and active month are exclusive filters
Give I am a user
And I have a search filter with `active:month`
When I select `active:week`
Then the `active:month` filter is replaced with `active:week`

Give I am a user
And I have a search filter with `active:week`
When I select `active:month`
Then the `active:week` filter is replaced with `active:month`

# Hover help text for `active:<weekday>` to say that it is any `<weekday>` in the last month