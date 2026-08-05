defmodule BikeBrigade.LocationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BikeBrigade.Locations` context.
  """

  @doc """
  Generate a community_fridge.
  """
  def community_fridge_fixture(attrs \\ %{}) do
    {:ok, community_fridge} =
      attrs
      |> Enum.into(%{
        active: true,
        description: "some description",
        name: "some name",
        pair_preferred: true,
        photo: "some photo"
      })
      |> BikeBrigade.Locations.create_community_fridge()

    community_fridge
  end
end
