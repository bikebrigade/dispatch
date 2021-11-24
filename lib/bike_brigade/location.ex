defmodule BikeBrigade.Location do
  use BikeBrigade.Schema

  alias BikeBrigade.Geocoder

  @primary_key false
  embedded_schema do
    field :coords, Geo.PostGIS.Geometry
    field :address, :string
    field :city, :string
    field :postal, :string
    field :province, :string
    field :country, :string
    field :unit, :string
    field :buzzer, :string
  end

  @type t :: %__MODULE__{
          coords: Geo.Point.t(),
          address: String.t(),
          city: String.t(),
          postal: String.t(),
          province: String.t(),
          country: String.t(),
          unit: String.t(),
          buzzer: String.t()
        }

  @doc """
  Fills in missing peices of a location struct using the Geocoder
  """
  @spec complete(__MODULE__.t()) :: {:ok, __MODULE__.t()} | {:error, any()}
  def complete(%__MODULE__{address: address, city: city, postal: postal} = location) do
    query =
      [address, city, postal]
      |> Enum.filter(&(!is_nil(&1) && &1 != ""))
      |> Enum.join(" ")

    case Geocoder.lookup(query) do
      {:ok, complete_location} ->
        updates = for {k, v} <- Map.from_struct(complete_location), !is_nil(v), do: {k, v}
        {:ok, struct(location, updates)}

      {:error, error} ->
        {:error, error}
    end
  end

  @spec set_coords(__MODULE__.t(), number(), number()) :: __MODULE__.t()
  def set_coords(location, lat, lon) do
    Map.put(location, :coords, %Geo.Point{coordinates: {lon, lat}, srid: 4326})
  end
end
