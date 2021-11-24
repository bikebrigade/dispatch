defmodule BikeBrigade.Location do
  defstruct [
    :lat,
    :lon,
    :address,
    :city,
    :postal,
    :province,
    :country,
    :unit,
    :buzzer
  ]

  @type t :: %__MODULE__{
          lat: number(),
          lon: number(),
          address: String.t(),
          city: String.t(),
          postal: String.t(),
          province: String.t(),
          country: String.t(),
          unit: String.t(),
          buzzer: String.t()
        }
end
