defmodule BikeBrigade.Locations.Location do
  use BikeBrigade.Schema
  import Ecto.Changeset

  alias BikeBrigade.Geocoder
  alias BikeBrigade.Locations.LocationNeighborhood

  @fields [:coords, :address, :city, :postal, :province, :country, :unit, :buzzer]
  @user_provided_fields [:address, :unit, :buzzer]

  schema "locations" do
    field :coords, Geo.PostGIS.Geometry, default: %Geo.Point{}
    field :address, :string
    field :city, :string, default: "Toronto"
    field :postal, :string
    field :province, :string, default: "Ontario"
    field :country, :string, default: "Canada"
    field :unit, :string
    field :buzzer, :string

    has_one :location_neighborhood, LocationNeighborhood
    has_one :neighborhood, through: [:location_neighborhood, :neighborhood]

    timestamps()
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
      for {k, v} <- Map.put(location, :unit, unit),
          !is_nil(v),
          reduce: cs do
        cs -> put_change(cs, k, v)
      end
    else
      {:data, _} -> cs
      {:error, error} -> add_error(cs, :address, "#{error}")
      :error -> add_error(cs, :address, "unknown error")
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

  defimpl String.Chars do
    alias BikeBrigade.Locations.Location

    def to_string(location) do
      address =
        if not is_nil(location.address) do
          unit = if not is_nil(location.unit), do: "Unit #{location.unit}"
          buzzer = if not is_nil(location.buzzer), do: "(Buzz #{location.buzzer})"

          [location.address, unit, buzzer]
          |> Enum.reject(&is_nil/1)
          |> Enum.join(" ")
        end

      [address, location.postal, location.city]
      |> Enum.reject(&is_nil/1)
      |> Enum.join(", ")
    end
  end

  defimpl Phoenix.HTML.Safe do
    alias BikeBrigade.Locations.Location

    def to_iodata(location) do
      String.Chars.to_string(location)
    end
  end
end
