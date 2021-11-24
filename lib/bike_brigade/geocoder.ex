defmodule BikeBrigade.Geocoder do
  use BikeBrigade.Adapter, :geocoder

  alias BikeBrigade.Location

  @callback lookup(pid, String.t()) :: {:ok, Location.t()} | {:error, any()}

  @doc """
  Looks up a given `search` query and returns a `Location` object
  """
  @spec lookup(String.t(), Keyword.t()) :: {:ok, Location.t()} | {:error, any()}
  def lookup(search, opts \\ [])

  def lookup(search, opts) when is_binary(search) do
    module = Keyword.get(opts, :module, @geocoder)
    pid = Keyword.get(opts, :pid, module)

    case module.lookup(pid, search) do
      {:ok, location} -> {:ok, location}
      {:error, reason} -> {:error, reason}
    end
  end

  def lookup(nil, opts), do: lookup("", opts)
end
