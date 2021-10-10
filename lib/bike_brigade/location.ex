defmodule BikeBrigade.Location do
  defstruct [
    :lat,
    :lon,
    :city,
    :postal,
    :province,
    :country
  ]

  @type t :: %__MODULE__{
          lat: number(),
          lon: number(),
          city: String.t(),
          postal: String.t(),
          province: String.t(),
          country: String.t()
        }

  def new(%{
        lat: lat,
        lon: lon,
        city: city,
        postal: postal,
        province: province,
        country: country
      }) do
    %__MODULE__{
      lat: lat,
      lon: lon,
      city: city,
      postal: postal,
      province: province,
      country: country
    }
  end
end
