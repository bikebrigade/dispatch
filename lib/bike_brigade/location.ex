defmodule BikeBrigade.Location do
  alias BikeBrigade.Geocoder

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

  @doc """
  Fills in missing peices of a location struct using the Geocoder
  """
  @spec complete(__MODULE__.t()) :: {:ok, __MODULE__.t()} | {:error, any()}
  def complete(%__MODULE__{address: address, city: city, postal: postal}) do
    [address, city, postal]
    |> Enum.filter(&(!is_nil(&1) && &1 != ""))
    |> Enum.join(" ")
    |> Geocoder.lookup()
  end
end
