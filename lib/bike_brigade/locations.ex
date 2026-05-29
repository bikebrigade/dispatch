defmodule BikeBrigade.Locations do
  import Ecto.Query, warn: false
  alias BikeBrigade.Repo

  alias BikeBrigade.Locations.CommunityFridge
  alias BikeBrigade.Locations.Location

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

  def list_community_fridges(opts \\ []) do
    preload = Keyword.get(opts, :preload, [:location])

    query =
      from cf in CommunityFridge,
        as: :community_fridge,
        order_by: [desc: cf.active, asc: cf.name]

    query =
      if search = opts[:search] do
        query
        |> where([community_fridge: cf], ilike(cf.name, ^"%#{search}%"))
      else
        query
      end

    query
    |> Repo.all()
    |> Repo.preload(preload)
  end

  def get_community_fridge!(id, opts \\ []) do
    preload = Keyword.get(opts, :preload, [])

    Repo.get!(CommunityFridge, id)
    |> Repo.preload(preload)
  end

  def get_community_fridge_by_name(name, opts \\ []) do
    preload = Keyword.get(opts, :preload, [])

    CommunityFridge
    |> Repo.get_by(name: name)
    |> Repo.preload(preload)
  end

  def create_community_fridge(attrs \\ %{}) do
    %CommunityFridge{}
    |> CommunityFridge.changeset(attrs)
    |> Repo.insert()
  end

  def update_community_fridge(%CommunityFridge{} = community_fridge, attrs \\ %{}) do
    community_fridge
    |> CommunityFridge.changeset(attrs)
    |> Repo.update()
  end

  def delete_community_fridge(%CommunityFridge{} = community_fridge) do
    Repo.delete(community_fridge)
  end
end
