defmodule BikeBrigade.Riders.RiderSearch do
  import Ecto.Query

  alias BikeBrigade.Repo

  alias BikeBrigade.Riders.{Rider, RiderSearch}
  alias BikeBrigade.Riders.Tag

  defstruct [:offset, :limit, :filters, :sort_field, :sort_order, :preload, total: 0, riders: []]

  @type t :: %RiderSearch{
          offset: non_neg_integer(),
          limit: non_neg_integer(),
          total: non_neg_integer(),
          filters: list(),
          sort_field: atom(),
          sort_order: atom(),
          preload: list(),
          riders: list()
        }

  @sort_orders [:desc, :asc]
  @sortable_fields [:name, :capacity, :last_active, :phone, :name_or_phone]
  @default_opts [
    sort_field: :last_active,
    sort_order: :desc,
    offset: 0,
    limit: 20,
    filters: [],
    preload: []
  ]

  @spec new(keyword()) :: RiderSearch.t()
  def new(opts \\ []) do
    opts = Keyword.merge(@default_opts, opts)

    %RiderSearch{
      offset: opts[:offset],
      limit: opts[:limit],
      filters: opts[:filters],
      sort_order: opts[:sort_order],
      sort_field: opts[:sort_field],
      preload: opts[:preload]
    }
    |> execute_query()
    |> update_total()
  end

  @spec filter(t(), list()) :: t()
  def filter(rs, filters) do
    %{rs | filters: filters, offset: 0}
    |> execute_query()
    |> update_total()
  end

  @spec sort(t(), atom(), atom()) :: t()
  def sort(rs, field, order)
      when field in @sortable_fields and order in @sort_orders do
    %{rs | sort_field: field, sort_order: order}
    |> execute_query()
    |> update_total()
  end

  @spec has_next_page?(t()) :: boolean()
  def has_next_page?(%{limit: limit, offset: offset, total: total}) do
    offset + limit < total
  end

  @spec has_prev_page?(t()) :: boolean()
  def has_prev_page?(%{offset: offset}) do
    offset > 0
  end

  @spec next_page(t()) :: t()
  def next_page(%{limit: limit, offset: offset, total: total} = rs) do
    # Only move to next page if we have one
    if limit + offset <= total do
      %{rs | offset: offset + limit}
      |> execute_query()
    else
      rs
    end
  end

  @spec prev_page(t()) :: t()
  def prev_page(%{limit: limit, offset: offset} = rs) do
    # Only move to next page if we have one
    if offset > 0 do
      %{rs | offset: max(offset - limit, 0)}
    else
      rs
    end
  end

  @spec page_first(t()) :: pos_integer()
  def page_first(%{offset: offset}) do
    offset + 1
  end

  @spec page_last(t()) :: pos_integer()
  def page_last(%{offset: offset, limit: limit, total: total}) do
    min(offset + limit + 1, total)
  end

  @spec execute_query(t()) :: t()
  defp execute_query(rs) do
    riders =
      base_query()
      |> sort_query(rs.sort_field, rs.sort_order)
      |> filter_query(rs.filters)
      |> paginate_query(rs.offset, rs.limit)
      |> Repo.all()
      |> Repo.preload(rs.preload)

    %{rs | riders: riders}
  end

  @spec update_total(t()) :: t()
  defp update_total(rs) do
    total =
      base_query()
      |> exclude(:preload)
      |> exclude(:order_by)
      |> exclude(:select)
      |> exclude(:limit)
      |> exclude(:offset)
      |> select(count())
      |> Repo.one()

    %{rs | total: total}
  end

  @spec base_query() :: Ecto.Query.t()
  defp base_query do
    tags_query =
      from(t in Tag,
        join: r in assoc(t, :riders),
        where: r.id == parent_as(:rider).id,
        select: %{tags: fragment("array_agg(?)", t.name)}
      )

    from(r in Rider,
      as: :rider,
      left_lateral_join: t in subquery(tags_query),
      as: :tags,
      left_join: l in assoc(r, :latest_campaign),
      as: :latest_campaign
    )
  end

  @spec paginate_query(Ecto.Query.t(), non_neg_integer(), non_neg_integer()) :: Ecto.Query.t()
  defp paginate_query(query, offset, limit) do
    query
    |> offset(^offset)
    |> limit(^limit)
  end

  @spec sort_query(Ecto.Query.t(), atom(), atom()) :: Ecto.Query.t()
  defp sort_query(query, :last_active, order)
       when order in @sort_orders do
    order = :"#{order}_nulls_last"

    query
    |> order_by([{^order, as(:latest_campaign).delivery_start}, asc: :name])
  end

  defp sort_query(query, field, order) do
    query
    |> order_by([{^order, ^field}])
  end

  @spec filter_query(Ecto.Query.t(), list()) :: Ecto.Query.t()
  defp filter_query(query, filters) do
    Enum.reduce(filters, query, &apply_filter/2)
  end

  @spec apply_filter({atom(), any()}, Ecto.Query.t()) :: Ecto.Query.t()
  defp apply_filter({:name, search}, query) do
    query
    |> where(ilike(as(:rider).name, ^"#{search}%"))
  end

  defp apply_filter({:phone, search}, query) do
    query
    |> where(like(as(:rider).phone, ^"%#{search}%"))
  end

  defp apply_filter({:name_or_phone, search}, query) do
    query
    |> where(ilike(as(:rider).name, ^"#{search}%") or like(as(:rider).phone, ^"%#{search}%"))
  end

  defp apply_filter({:tag, tag}, query) do
    query
    |> where(fragment("? = ANY(?)", ^tag, as(:tags).tags))
  end

  defp apply_filter({:capacity, capacity}, query) do
    # TODO this may be easier with Ecto.Enum instead of EctoEnum
    {:ok, capacity} = Rider.CapacityEnum.dump(capacity)

    query
    |> where(as(:rider).capacity == ^capacity)
  end

  defp apply_filter({:active, :never}, query) do
    query
    |> where(is_nil(as(:latest_campaign).id))
  end

  defp apply_filter({:active, period}, query) do
    query
    |> where(as(:latest_campaign).delivery_start > ago(1, ^period))
  end
end
