defmodule BikeBrigade.Geocoder do
  use BikeBrigade.Adapter, :geocoder

  alias BikeBrigade.Location

  @callback lookup(pid, String.t()) :: {:ok, Location.t()} | {:error, any()}

  @spec lookup(String.t(), Keyword.t()) :: {:ok, Location.t()} | {:error, any()}
  def lookup(address, opts \\ [])
  def lookup(address, opts) when is_binary(address) do
    module = Keyword.get(opts, :module, @geocoder)
    pid = Keyword.get(opts, :pid, module)

    address =
      if String.ends_with?(address, "Toronto") do
        address
      else
        address <> " Toronto"
      end

    case module.lookup(pid, address) do
      {:ok, location} -> {:ok, location}
      {:error, reason} -> {:error, reason}
    end
  end

  def lookup(nil, opts), do: lookup("", opts)
end
