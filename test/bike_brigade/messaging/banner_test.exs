defmodule BikeBrigade.Messaging.BannerTest do
  use BikeBrigade.DataCase, async: true

  alias BikeBrigade.Messaging

  describe "Banners" do

    test "create_banner works" do
      turn_on_time = DateTime.utc_now()
      turn_off_time = DateTime.utc_now() |> DateTime.add(1, :day)
      
      result = Messaging.create_banner(%{
        message: "foo",
        created_by_id: 1,
        turn_on_at: turn_on_time,
        turn_off_at: turn_off_time
      })
      
      # Assert the operation was successful
      assert {:ok, _banner} = result
    end
  end
end
