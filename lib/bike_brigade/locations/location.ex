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
    field :coords, Geo.PostGIS.Geometry, default: nil
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
    |> validate_change(:coords, fn :coords, coords ->
      if %Geo.Point{coordinates: {0, 0}} = coords do
        [location: "location is invalid"]
      else
        []
      end
    end)
  end

  # TODO remove this and replace with `change_location` / the new live location widget
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

  @doc """
  Change location with a given field
  """
  def change_location(location, :smart_input, value) do
    if is_partial_postal?(value) do
      change_location(location, :postal, value)
    else
      change_location(location, :address, value)
    end
  end

  def change_location(location, :address, "") do
    change(location, %{address: ""})
  end

  def change_location(location, :address, address) do
    case Geocoder.lookup(address) do
      {:ok, geocoded_params} ->
        change(location, reset_notes(geocoded_params))

      {:error, _} ->
        change(location, %{address: address})
        |> add_error(:location, "unable to lookup address")
    end
  end

  def change_location(location, :postal, postal) do
    with {:ok, parsed_postal} <- parse_postal_code(postal),
         {:ok, geocoded_params} <- Geocoder.lookup(parsed_postal) do
      change(location, reset_notes(geocoded_params))
    else
      {:error, :partial_postal} ->
        # Don't add errors if the postal is partial
        change(location, reset_notes(%{postal: postal}))

      {:error, _} ->
        change(location, reset_notes(%{postal: postal}))
        |> add_error(:location, "invalid postal code")
    end
  end

  def change_location(location, :unit, unit) do
    change(location, %{unit: unit})
  end

  def change_location(location, :buzzer, buzzer) do
    change(location, %{buzzer: buzzer})
  end

  def change_location(location, _field, _value) do
    change(location)
  end

  defp reset_notes(params) do
    Map.merge(params, %{unit: nil, buzzer: nil})
  end

  @postal_regex [
                  # A
                  "^[[:alpha:]]$|",
                  # A1
                  "^[[:alpha:]][[:digit:]]$|",
                  # A1A
                  "^[[:alpha:]][[:digit:]][[:alpha:]]$|",
                  # A1A 1
                  "^[[:alpha:]][[:digit:]][[:alpha:]][[:space:]]*[[:digit:]]$|",
                  # A1A 1A
                  "^[[:alpha:]][[:digit:]][[:alpha:]][[:space:]]*[[:digit:]][[:alpha:]]$|",
                  # A1A 1A1 (with captures)
                  "^([[:alpha:]][[:digit:]][[:alpha:]])[[:space:]]*([[:digit:]][[:alpha:]][[:digit:]])$"
                ]
                |> Enum.join()
                |> Regex.compile!()

  @doc """
  Parse a postal code, returning one of:
    * `{:ok, formated_postal_code}`
    * `{:error, :partial_postal}`
    * `{:error, :invalid_postal}`
  """
  def parse_postal_code(value) do
    case Regex.run(@postal_regex, String.trim(value)) do
      [_, left, right] ->
        {:ok, String.upcase("#{left} #{right}")}

      [_] ->
        {:error, :partial_postal}

      nil ->
        {:error, :invalid_postal}
    end
  end

  defp is_partial_postal?(value) do
    case parse_postal_code(value) do
      {:ok, _postal} -> true
      {:error, :partial_postal} -> true
      _ -> false
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
    def to_iodata(location) do
      String.Chars.to_string(location)
    end
  end
end
