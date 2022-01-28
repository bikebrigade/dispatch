defmodule BikeBrigade.Geocoder do
  use BikeBrigade.Adapter, :geocoder

  alias BikeBrigade.Location

  @neighborhoods :code.priv_dir(:bike_brigade)
                 |> Path.join("repo/seeds/toronto_crs84.geojson")
                 |> File.read!()
                 |> Jason.decode!()
                 |> Geo.JSON.decode!()

  @callback lookup(pid, String.t()) :: {:ok, Location.t()} | {:error, any()}

  @doc """
  Looks up a given `search` query and returns a `Location` object
  """
  @spec lookup(String.t(), Keyword.t()) :: {:ok, Location.t()} | {:error, any()}
  def lookup(search, opts \\ [])

  def lookup(search, opts) when is_binary(search) do
    module = Keyword.get(opts, :module, @geocoder)
    pid = Keyword.get(opts, :pid, module)

    case module.lookup(pid, search) do
      {:ok, location} ->
        location = %{location | neighborhood: get_neighborhood(location.coords)}
        {:ok, location}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def lookup(nil, opts), do: lookup("", opts)

  @deprecated "To be removed when moving to Location.geocode_changeset"
  def lookup_toronto(address, opts \\ []) do
    lookup(address <> " Toronto", opts)
  end

  def get_neighborhood(coords) do
    @neighborhoods.geometries
    |> Enum.find_value(fn geo ->
      if Topo.contains?(geo, coords) do
        Regex.replace(~r/(.*) \(\d+\)/, geo.properties["AREA_NAME"], "\\1")
      end
    end)
  end
end
