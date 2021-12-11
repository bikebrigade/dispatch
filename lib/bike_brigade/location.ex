defmodule BikeBrigade.Location do
  use BikeBrigade.Schema
  import Ecto.Changeset

  alias BikeBrigade.Geocoder

  @fields [:coords, :address, :neighborhood, :city, :postal, :province, :country, :unit, :buzzer]

  @primary_key false
  embedded_schema do
    field :coords, Geo.PostGIS.Geometry, default: %Geo.Point{}
    field :address, :string
    field :neighborhood, :string
    field :city, :string, default: "Toronto"
    field :postal, :string
    field :province, :string, default: "Ontario"
    field :country, :string, default: "Canada"
    field :unit, :string
    field :buzzer, :string
  end

  @type t :: %__MODULE__{
          coords: Geo.Point.t(),
          address: String.t(),
          neighborhood: String.t(),
          city: String.t(),
          postal: String.t(),
          province: String.t(),
          country: String.t(),
          unit: String.t(),
          buzzer: String.t()
        }

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> validate_required([:coords, :city, :province, :country])
  end

  @doc """
  Fills in missing peices of a location struct using the Geocoder
  """
  @spec complete(__MODULE__.t()) :: {:ok, __MODULE__.t()} | {:error, any()}
  def complete(location) do
    location = fill_unit(location)

    query =
      "#{location.address} #{location.city} #{location.postal}"
      |> String.trim()
      |> String.replace(~r/\s+/, " ")

    case Geocoder.lookup(query) do
      {:ok, complete_location} ->
        updates = for {k, v} <- Map.from_struct(complete_location), !is_nil(v), do: {k, v}

        {:ok, struct(location, updates)}

      {:error, error} ->
        {:error, error}
    end
  end

  defp fill_unit(%__MODULE__{address: address} = location) when is_binary(address) do
    case Regex.run(~r/^\s*(?<unit>[^\s]+)\s*-\s*(?<address>.*)$/, address) do
      [_, unit, parsed_address] ->
        %{location | address: parsed_address, unit: unit}

      _ ->
        location
    end
  end

  defp fill_unit(location), do: location

  @spec set_coords(__MODULE__.t(), number(), number()) :: __MODULE__.t()
  def set_coords(location, lat, lon) when is_float(lat) and is_float(lon) do
    Map.put(location, :coords, %Geo.Point{coordinates: {lon, lat}, srid: 4326})
  end

  def set_coords(location, lat, lon) when is_binary(lat) and is_binary(lon) do
    set_coords(location, String.to_float(lat), String.to_float(lon))
  end

  defimpl String.Chars do
    def to_string(location) do
      "#{location.address}, #{location.city}, #{location.postal}"
    end
  end
end
