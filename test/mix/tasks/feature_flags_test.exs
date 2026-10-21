defmodule Mix.Tasks.FeatureFlagsTest do
  use BikeBrigade.DataCase

  alias BikeBrigade.Accounts

  setup do
    Mix.shell(Mix.Shell.Process)
    on_exit(fn -> Mix.shell(Mix.Shell.IO) end)
  end

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

  test "rejects flags that aren't defined" do
    user = fixture(:user)

    Mix.Tasks.FeatureFlags.run(["users", "unified_mesaging", "100"])

    assert_received {:mix_shell, :error, [message]}
    assert message =~ ~s(Unknown flag "unified_mesaging")
    assert message =~ "unified_messaging"
    refute Accounts.get_user(user.id).flags.unified_messaging

    Mix.Tasks.FeatureFlags.run(["not_a_rider_flag", "100"])
    assert_received {:mix_shell, :error, ["Unknown flag \"not_a_rider_flag\"" <> _]}
  end
end
