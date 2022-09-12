defmodule BikeBrigade.Locations.Location do
  use BikeBrigade.Schema
  import Ecto.Changeset

  alias BikeBrigade.Geocoder
  alias BikeBrigade.Locations.LocationNeighborhood

  alias BikeBrigade.Riders.Rider
  alias BikeBrigade.Delivery.{Campaign, Opportunity, Task}

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

    has_one :rider, Rider, on_delete: :nilify_all
    has_one :campaign, Campaign, on_delete: :nilify_all
    has_one :task_dropoff, Task, foreign_key: :dropoff_location_id, on_delete: :nilify_all
    has_one :task_pickup, Task, foreign_key: :pickup_location_id, on_delete: :nilify_all
    has_one :opportunity, Opportunity, on_delete: :nilify_all

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

  def print_address(location) do
    case location do
      %{unit: nil, buzzer: nil, address: address} ->
        address

      %{unit: unit, buzzer: nil, address: address} ->
        "#{address} Unit #{unit}"

      %{unit: nil, buzzer: buzzer, address: address} ->
        "#{address} (Buzz #{buzzer})"

      %{unit: unit, buzzer: buzzer, address: address} ->
        "#{address} Unit #{unit} (Buzz #{buzzer})"
    end
  end

  defimpl String.Chars do
    alias BikeBrigade.Locations.Location

    def to_string(location) do
      "#{Location.print_address(location)}, #{location.city}, #{location.postal}"
    end
  end

  defimpl Phoenix.HTML.Safe do
    alias BikeBrigade.Locations.Location

    def to_iodata(location) do
      [Location.print_address(location), ", ", location.city, ", ", location.postal]
    end
  end
end
