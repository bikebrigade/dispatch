defmodule BikeBrigade.Messaging.BannerTest do
  use BikeBrigade.DataCase, async: true

  alias BikeBrigade.Messaging

  describe "Banners" do
    test "create_banner" do
      turn_on_time = DateTime.utc_now()
      turn_off_time = DateTime.utc_now() |> DateTime.add(1, :day)
      user = fixture(:user, %{is_dispatcher: true})

      result =
        Messaging.create_banner(%{
          message: "foo",
          created_by_id: user.id,
          turn_on_at: turn_on_time,
          turn_off_at: turn_off_time
        })

      assert {:ok, _banner} = result
    end

    test "list_banners" do
      for _n <- 1..4 do
        fixture(:banner)
      end

      assert Enum.count(Messaging.list_banners()) == 4
    end

    test "update_banner" do
      b = fixture(:banner)
      {:ok, b2} = Messaging.update_banner(b, %{message: "bar"})
      assert b2.message == "bar"
    end
  end
end
