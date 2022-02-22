defmodule BikeBrigade.GoogleMaps do
  import BikeBrigade.Utils, only: [get_config: 1]

  alias BikeBrigade.Location

  def embed_map_url(%Location{} = location) do
    location
    |> String.Chars.to_string()
    |> embed_map_url()
  end

  def embed_map_url(address) when is_binary(address) do
    "https://www.google.com/maps/embed/v1/place?key=#{get_config(:api_key)}&q=#{URI.encode(address)}"
  end

  def open_map_url(%Location{} = location) do
    location
    |> String.Chars.to_string()
    |> open_map_url()
  end

  def open_map_url(address) when is_binary(address) do
    "https://www.google.com/maps/search/?api=1&query=#{URI.encode(address)}"
  end

  def embed_directions_url(origin, addresses) do
    q = map_query(origin, addresses)

    "//www.google.com/maps/embed/v1/directions?key=#{get_config(:api_key)}&mode=bicycling&#{q}"
  end

  def directions_url(origin, addresses) do
    q = map_query(origin, addresses)

    "https://www.google.com/maps/dir/?api=1&travelmode=bicycling&#{q}"
  end

  def map_query(origin, addresses) do
    # Origin or addresses can be Locations or Strings
    origin = String.Chars.to_string(origin)
    addresses = Enum.map(addresses, &String.Chars.to_string/1)

    {destination, waypoints} = List.pop_at(addresses, -1)

    query =
      if waypoints == [] do
        %{origin: origin, destination: destination}
      else
        %{origin: origin, destination: destination, waypoints: Enum.join(waypoints, "|")}
      end

    URI.encode_query(query)
  end
end
