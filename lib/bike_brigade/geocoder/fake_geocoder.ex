defmodule BikeBrigade.Geocoder.FakeGeocoder do
  use GenServer

  require Logger

  alias NimbleCSV.RFC4180, as: CSV

  @behaviour BikeBrigade.Geocoder

  def start_link(opts \\ []) do
    locations =
      case Keyword.get(opts, :locations, %{}) do
        :from_seeds -> load_locations_from_seeds()
        locations -> locations
      end

    gen_server_opts =
      case Keyword.get(opts, :name, :default) do
        :default -> [name: __MODULE__]
        nil -> []
        name -> [name: name]
      end

    GenServer.start_link(__MODULE__, locations, gen_server_opts)
  end

  def lookup(geocoder \\ __MODULE__, address) do
    GenServer.call(geocoder, {:lookup, address})
  end

  def inject_address(geocoder \\ __MODULE__, address, location) do
    GenServer.call(geocoder, {:inject_address, address, location})
  end

  def init(locations), do: {:ok, locations}

  def handle_call({:lookup, address}, _from, locations) do
    Logger.info(
      "Received FakeGeocoder lookup for #{address}. Only addresses from seeded data are valid."
    )

    result =
      case Map.get(locations, address, :not_found) do
        %{} = location -> {:ok, location}
        :not_found -> {:error, :not_found}
      end

    {:reply, result, locations}
  end

  def handle_call({:inject_address, address, location}, _from, locations) do
    locations = Map.put(locations, address, location)
    {:reply, :ok, locations}
  end

  def load_locations_from_seeds() do
    "priv/repo/seeds/toronto.csv"
    |> File.stream!()
    |> CSV.parse_stream()
    |> Enum.flat_map(fn [address, postal, city, lat, lon] ->
      address = address
      {lat, lon} = {String.to_float(lat), String.to_float(lon)}

      location = %{
        address: address,
        city: city,
        postal: postal,
        province: "Ontario",
        country: "Canada",
        coords: %Geo.Point{coordinates: {lon, lat}}
      }

      [{address, location}, {"#{address} #{city}", location}]
    end)
    |> Enum.into(%{})
  end
end
