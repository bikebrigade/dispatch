defmodule BikeBrigade.Locations do
  import Ecto.Query, warn: false

  alias BikeBrigade.Repo
  alias BikeBrigade.Locations.Location
  alias BikeBrigade.Locations.CommunityFridge

  def neighborhood(%Location{} = location) do
    if neighborhood = Repo.preload(location, :neighborhood).neighborhood do
      neighborhood.name
    else
      "Unknown"
    end
  end

  def neighborhood(nil) do
    "Unknown"
  end

  @doc """
  Returns the list of community_fridges.
  """
  def list_community_fridges do
    Repo.all(CommunityFridge)
  end

  @doc """
  Gets a single community_fridge.

  Raises `Ecto.NoResultsError` if the Community fridge does not exist.
  """
  def get_community_fridge!(id), do: Repo.get!(CommunityFridge, id)

  @doc """
  Creates a community_fridge.
  """
  def create_community_fridge(attrs \\ %{}) do
    %CommunityFridge{}
    |> CommunityFridge.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a community_fridge.
  """
  def update_community_fridge(%CommunityFridge{} = community_fridge, attrs) do
    community_fridge
    |> CommunityFridge.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a community_fridge.
  """
  def delete_community_fridge(%CommunityFridge{} = community_fridge) do
    Repo.delete(community_fridge)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking community_fridge changes.
  """
  def change_community_fridge(%CommunityFridge{} = community_fridge, attrs \\ %{}) do
    CommunityFridge.changeset(community_fridge, attrs)
  end
end
