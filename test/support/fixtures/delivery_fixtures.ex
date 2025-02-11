defmodule BikeBrigade.DeliveryFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BikeBrigade.Delivery` context.
  """

  @doc """
  Generate a announcement.
  """
  def announcement_fixture(attrs \\ %{}) do
    {:ok, announcement} =
      attrs
      |> Enum.into(%{
        message: "some message",
        turn_off_at: ~U[2025-02-10 22:26:00.000000Z],
        turn_on_at: ~U[2025-02-10 22:26:00.000000Z]
      })
      |> BikeBrigade.Delivery.create_announcement()

    announcement
  end
end
