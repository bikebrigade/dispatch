defmodule BikeBrigade.Messaging.MessageSearch do
  @moduledoc """
  Provides filtering and search capabilities for SMS messages.
  """

  defstruct filters: []

  defmodule Filter do
    @moduledoc """
    Represents a filter that can be applied to message searches.
    """
    @derive Jason.Encoder
    defstruct [:type, :search, :id]

    @type t :: %__MODULE__{
            type: atom(),
            search: String.t(),
            id: integer() | nil
          }
  end

  @type t :: %__MODULE__{
          filters: list(Filter.t())
        }

  @doc """
  Creates a new MessageSearch struct with optional filters.

  ## Examples

      iex> MessageSearch.new()
      %MessageSearch{filters: []}

      iex> MessageSearch.new(filters: [%Filter{type: :program, search: "Food Delivery", id: 1}])
      %MessageSearch{filters: [%Filter{type: :program, search: "Food Delivery", id: 1}]}
  """
  def new(opts \\ []) do
    %__MODULE__{
      filters: Keyword.get(opts, :filters, [])
    }
  end

  @doc """
  Updates the filters for a MessageSearch struct.

  ## Examples

      iex> ms = MessageSearch.new()
      iex> MessageSearch.filter(ms, [%Filter{type: :program, search: "Food", id: 1}])
      %MessageSearch{filters: [%Filter{type: :program, search: "Food", id: 1}]}
  """
  def filter(%__MODULE__{} = ms, filters) do
    %{ms | filters: filters}
  end
end
