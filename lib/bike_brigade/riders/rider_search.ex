defmodule BikeBrigade.Riders.RiderSearch do
  import Ecto.Query

  alias BikeBrigade.Repo

  alias BikeBrigade.Riders.{Rider, RiderSearch}
  alias BikeBrigade.Riders.Tag

  defstruct [
    :sort_field,
    :sort_order,
    :preload,
    offset: 0,
    limit: 0,
    filters: [],
    page_changed: true,
    query_changed: true
  ]

  @type t :: %RiderSearch{
          offset: non_neg_integer(),
          limit: non_neg_integer(),
          filters: list(),
          sort_field: atom(),
          sort_order: atom(),
          preload: list()
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

  defmodule Results do
    defstruct page: [], locations: [], total: 0, page_first: 0, page_last: 0

    @type t :: %Results{
            page: list(),
            locations: list(),
            total: non_neg_integer(),
            page_first: non_neg_integer(),
            page_last: non_neg_integer()
          }

    @spec has_next_page?(t()) :: boolean()
    def has_next_page?(%{page_last: page_last, total: total}) do
      page_last < total
    end

    @spec has_prev_page?(t()) :: boolean()
    def has_prev_page?(%{page_first: page_first}) do
      page_first > 1
    end
  end

  @spec new(keyword()) :: RiderSearch.t()
  def new(opts \\ []) do
    opts = Keyword.merge(@default_opts, opts)

    %RiderSearch{
      offset: opts[:offset],
      limit: opts[:limit],
      filters: opts[:filters],
      sort_order: opts[:sort_order],
      sort_field: opts[:sort_field],
      preload: opts[:preload],
      page_changed: true,
      query_changed: true
    }
  end

  @spec fetch(RiderSearch.t(), Results.t()) :: {RiderSearch.t(), Results.t()}
  def fetch(rs, results) do
    {rs, results} =
      {rs, results}
      |> fetch_total()
      |> fetch_page()

    {%{rs | query_changed: false, page_changed: false}, results}
  end

  @spec fetch_total({RiderSearch.t(), Results.t()}) :: {RiderSearch.t(), Results.t()}
  defp fetch_total({%RiderSearch{query_changed: false} = rs, results}) do
    {rs, results}
  end

  defp fetch_total({%RiderSearch{query_changed: true} = rs, results}) do
    total =
      build_query(rs)
      |> exclude(:preload)
      |> exclude(:order_by)
      |> exclude(:select)
      |> exclude(:limit)
      |> exclude(:offset)
      |> select(count())
      |> Repo.one()

    {%{rs | query_changed: true}, %{results | total: total}}
  end

  @spec fetch_page({RiderSearch.t(), Results.t()}) :: {RiderSearch.t(), Results.t()}
  defp fetch_page({%RiderSearch{page_changed: false} = rs, results}) do
    {rs, results}
  end

  defp fetch_page({%RiderSearch{page_changed: true} = rs, results}) do
    riders =
      build_query(rs)
      |> Repo.all()
      |> Repo.preload(rs.preload)

    page_first =
      if results.total == 0 do
        0
      else
        rs.offset + 1
      end

    page_last = min(rs.offset + rs.limit + 1, results.total)

    {%{rs | page_changed: true},
     %{results | page: riders, page_first: page_first, page_last: page_last}}
  end

  @spec filter(t(), list()) :: t()
  def filter(rs, filters) do
    %{rs | filters: filters, offset: 0, page_changed: true, query_changed: true}
  end

  @spec sort(t(), atom(), atom()) :: t()
  def sort(rs, field, order)
      when field in @sortable_fields and order in @sort_orders do
    %{rs | sort_field: field, sort_order: order, page_changed: true, query_changed: true}
  end

  @spec next_page(t()) :: t()
  def next_page(%{limit: limit, offset: offset} = rs) do
    %{rs | offset: offset + limit, page_changed: true}
  end

  @spec prev_page(t()) :: t()
  def prev_page(%{limit: limit, offset: offset} = rs) do
    # Only move to prev page if we have one
    if offset > 0 do
      %{rs | offset: max(offset - limit, 0), page_changed: true}
    else
      rs
    end
  end

  @spec build_query(t()) :: Ecto.Query.t()
  defp build_query(rs) do
    base_query()
    |> sort_query(rs.sort_field, rs.sort_order)
    |> filter_query(rs.filters)
    |> paginate_query(rs.offset, rs.limit)
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
    |> where(ilike(as(:rider).name, ^"#{search}%") or ilike(as(:rider).name, ^"% #{search}%"))
  end

  defp apply_filter({:phone, search}, query) do
    query
    |> where(like(as(:rider).phone, ^"%#{search}%"))
  end

  defp apply_filter({:name_or_phone, search}, query) do
    query
    |> where(
      ilike(as(:rider).name, ^"#{search}%") or ilike(as(:rider).name, ^"% #{search}%") or
        like(as(:rider).phone, ^"%#{search}%")
    )
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
