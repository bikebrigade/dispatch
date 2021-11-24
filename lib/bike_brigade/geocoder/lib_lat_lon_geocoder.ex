defmodule BikeBrigade.Geocoder.LibLatLonGeocoder do
  @behaviour BikeBrigade.Geocoder

  alias LibLatLon.Providers.GoogleMaps
  alias BikeBrigade.Location

  def lookup(_, search) do
    case GoogleMaps.lookup(search) do
      {:ok,
       %{
         coords: %{lat: lat, lon: lon},
         details: %{
           locality: city,
           postal_code: postal,
           administrative_area_level_1: province,
           country: country
         }
       }} ->
        {:ok,
         %Location{
           lat: lat,
           lon: lon,
           city: city,
           postal: postal,
           province: province,
           country: country
         }}

      {:ok, _} ->
        {:error, "unable to geolocate address"}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
