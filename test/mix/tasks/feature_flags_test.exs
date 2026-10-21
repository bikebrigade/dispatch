defmodule Mix.Tasks.FeatureFlagsTest do
  use BikeBrigade.DataCase

  alias BikeBrigade.Accounts

  test "rolls a flag out to users" do
    user = fixture(:user)

    Mix.Tasks.FeatureFlags.run(["users", "unified_messaging", "100"])
    assert Accounts.get_user(user.id).flags.unified_messaging

    Mix.Tasks.FeatureFlags.run(["users", "unified_messaging", "0"])
    refute Accounts.get_user(user.id).flags.unified_messaging
  end

  test "rolls a flag out to riders" do
    rider = fixture(:rider, %{flags: %{opt_in_to_new_number: false}})

    Mix.Tasks.FeatureFlags.run(["opt_in_to_new_number", "100"])
    assert BikeBrigade.Riders.get_rider(rider.id).flags.opt_in_to_new_number
  end
end
