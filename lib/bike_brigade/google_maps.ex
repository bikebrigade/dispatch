defmodule BikeBrigade.GoogleMaps do
  import BikeBrigade.Utils, only: [get_config: 1]

  alias BikeBrigade.Locations.Location

  def embed_map_url(%Location{} = location) do
    location
    |> print_address()
    |> embed_map_url()
  end

  def embed_map_url(address) when is_binary(address) do
    "https://www.google.com/maps/embed/v1/place?key=#{get_config(:api_key)}&q=#{URI.encode(address)}"
  end

  def open_map_url(%Location{} = location) do
    location
    |> print_address()
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
    origin = print_address(origin)
    addresses = Enum.map(addresses, &print_address/1)

    {destination, waypoints} = List.pop_at(addresses, -1)

    query =
      if waypoints == [] do
        %{origin: origin, destination: destination}
      else
        %{origin: origin, destination: destination, waypoints: Enum.join(waypoints, "|")}
      end

    URI.encode_query(query)
  end

  defp print_address(address) when is_binary(address) do
    address
  end

  defp print_address(%Location{address: address, postal: postal}) do
    "#{address} #{postal}"
  end
end
