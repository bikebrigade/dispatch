defmodule BikeBrigade.FixturesTest do
  use BikeBrigade.DataCase

  for kind <- [:user, :rider] do
    @kind kind

    test "#{kind} contact identifiers stay unique when random data repeats" do
      seed = :rand.seed(:exsss, {11, 22, 33})
      first = fixture(@kind)
      :rand.seed(seed)
      second = fixture(@kind)

      assert first.name == second.name
      refute first.email == second.email
      refute first.phone == second.phone
    end
  end
end
