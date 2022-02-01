defmodule BikeBrigade.QueryContext do
  alias BikeBrigade.QueryContext

  @moduledoc """
  Pagination and sorting for arbitrary Ecto schemas

  Somewhat inspired by https://github.com/drewolson/scrivener

  We're using LIMIT/OFFSET right now. Cursor-based paging is more efficient
  but can be harder to implement if we also want to support arbitrary sorting.

  See https://github.com/duffelhq/paginator for an example of cursor-based paging
  built on top of Ecto
  """

  defstruct [:sort, :pager]

  @type t :: %QueryContext{sort: Sort.t(), pager: Pager.t() | nil}

  defmodule Sort do
    defstruct [:field, :order]

    @type t :: %Sort{field: atom(), order: order()}
    @type field :: atom()
    @type order :: :desc | :asc
  end

  defmodule Pager do
    defstruct [:offset, :limit]

    @type t :: %Pager{offset: offset(), limit: limit()}
    @type offset :: non_neg_integer()
    @type limit :: pos_integer()
  end

  @spec new(Sort.field(), Sort.order()) :: QueryContext.t()
  def new(sort_field, sort_order) do
    %QueryContext{sort: %Sort{field: sort_field, order: sort_order}, pager: nil}
  end

  @spec new(Sort.field(), Sort.order(), Pager.limit()) :: QueryContext.t()
  def new(sort_field, sort_order, limit) do
    %QueryContext{
      sort: %Sort{field: sort_field, order: sort_order},
      pager: %Pager{offset: 0, limit: limit}
    }
  end

  @spec sort(QueryContext.t(), Sort.field(), Sort.order()) :: QueryContext.t()
  def sort(%QueryContext{pager: pager} = ctx, sort_field, sort_order) do
    pager =
      case pager do
        %Pager{} = p -> %{p | offset: 0}
        nil -> nil
      end

    %{ctx | sort: %Sort{field: sort_field, order: sort_order}, pager: pager}
  end

  @spec next_page(QueryContext.t()) :: QueryContext.t()
  def next_page(%QueryContext{pager: nil} = ctx), do: ctx

  def next_page(%QueryContext{pager: pager} = ctx) do
    %{ctx | pager: %{pager | offset: pager.offset + pager.limit}}
  end

  @spec prev_page(QueryContext.t()) :: QueryContext.t()
  def prev_page(%QueryContext{pager: nil} = ctx), do: ctx

  def prev_page(%QueryContext{pager: pager} = ctx) do
    %{ctx | pager: %{pager | offset: max(0, pager.offset - pager.limit)}}
  end
end
