defmodule BikeBrigade.Repo.Seeds.Toronto do
  alias BikeBrigade.Location

  defmodule LoadAddresses do
    alias NimbleCSV.RFC4180, as: CSV

    defmacro __before_compile__(env) do
      addrs =
        env.file
        |> Path.dirname()
        |> Path.join("toronto.csv")
        |> File.read!()
        |> CSV.parse_string()
        |> Enum.map(fn [address, postal, city, lat, lon] ->
          [address, postal, city, String.to_float(lat), String.to_float(lon)]
        end)

      quote do
        def addresses, do: unquote(addrs)
      end
    end
  end

  @before_compile LoadAddresses

  def random_address do
    [address, postal, city, lat, lng] = Enum.random(addresses())

    %{
      address: address,
      postal: postal,
      city: city,
      lat: lat,
      lng: lng,
      country: "Canada",
      province: "Ontario"
    }
  end

  def to_location(%{lat: lat, lng: lng, city: city, postal: postal}) do
    %Location{
      city: city,
      postal: postal,
      province: "Ontario",
      country: "Canada"
    }
    |> Location.set_coords(lat, lng)
  end
end
