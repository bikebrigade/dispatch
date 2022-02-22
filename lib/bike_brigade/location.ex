defmodule BikeBrigade.Location do
  use BikeBrigade.Schema
  import Ecto.Changeset

  alias BikeBrigade.Geocoder

  @fields [:coords, :address, :neighborhood, :city, :postal, :province, :country, :unit, :buzzer]
  @user_provided_fields [:address, :unit, :buzzer]

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

  def geocoding_changeset(struct, params \\ %{}) do
    cs =
      struct
      |> cast(params, @user_provided_fields)

    with {:changes, address} <- fetch_field(cs, :address),
         {address, unit} <- parse_unit(address),
         {_, city} <- fetch_field(cs, :city),
         {:ok, location} <- String.trim("#{address} #{city}") |> Geocoder.lookup() do
      for {k, v} <- %{location | unit: unit} |> Map.from_struct(),
          !is_nil(v),
          reduce: cs do
        cs -> put_change(cs, k, v)
      end
    else
      {:data, _} -> cs
      {:error, error} -> add_error(cs, :address, "#{error}")
      :error ->  add_error(cs, :address, "unknown error")
    end
  end

  defp parse_unit(address) when is_binary(address) do
    case Regex.run(~r/^\s*(?<unit>[^\s]+)\s*-\s*(?<address>.*)$/, address) do
      [_, unit, parsed_address] ->
        {parsed_address, unit}

      _ ->
        {address, nil}
    end
  end

  defp parse_unit(address), do: {address, nil}

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

  defimpl Phoenix.HTML.Safe do
    def to_iodata(location) do
      [location.address, ", ", location.city, ", ", location.postal]
    end
  end
end
