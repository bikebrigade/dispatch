defmodule BikeBrigade.Riders.RiderSearch do
  import Ecto.Query

  alias BikeBrigade.Repo

  alias BikeBrigade.Riders.{Rider, RiderSearch, Tag}
  alias BikeBrigade.Stats.RiderStats

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
  @sortable_fields [:name, :capacity, :last_active, :phone]
  @default_opts [
    sort_field: :last_active,
    sort_order: :desc,
    offset: 0,
    limit: 20,
    filters: [],
    preload: []
  ]

  @weekdays %{
    "monday" => 1,
    "tuesday" => 2,
    "wednesday" => 3,
    "thursday" => 4,
    "friday" => 5,
    "saturday" => 6,
    "sunday" => 7
  }
  @weekday_names Map.keys(@weekdays)
  @timezone "America/Toronto"

  # Thresholds for weekday filtering
  # Applied to ALL weekday searches (solo and combined with time period)
  @lookback_period_years 1
  # Applied ONLY to solo weekday searches (min deliveries on a weekday)
  @volume_threshold 3
  # Applied ONLY to solo weekday searches (recent delivery requirement)
  @recency_threshold_months 3

  defmodule Filter do
    @derive Jason.Encoder
    defstruct [:type, :search, :id]

    @type t :: %Filter{type: atom(), search: String.t(), id: integer() | nil}
  end

  defmodule Results do
    defstruct page: [], all_locations: [], total: 0, page_first: 0, page_last: 0

    @type t :: %Results{
            page: list(),
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

  @spec fetch(RiderSearch.t()) :: {RiderSearch.t(), Results.t()}
  @spec fetch(RiderSearch.t(), Results.t()) :: {RiderSearch.t(), Results.t()}
  def fetch(rs, results \\ %Results{}) do
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

    {rs, %{results | total: total}}
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

    {rs, %{results | page: riders, page_first: page_first, page_last: page_last}}
  end

  @spec fetch_locations(RiderSearch.t()) :: list()
  def fetch_locations(rs) do
    build_query(rs)
    |> exclude(:preload)
    |> exclude(:order_by)
    |> exclude(:select)
    |> exclude(:limit)
    |> exclude(:offset)
    |> join(:inner, [rider: r], l in assoc(r, :location), as: :location)
    |> select([rider: r, location: l], {r.id, r.name, l})
    |> Repo.all()
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
        select: %{rider_id: r.id, tags: fragment("array_agg(?)", t.name)},
        group_by: r.id
      )

    from(r in Rider,
      as: :rider,
      left_join: t in subquery(tags_query),
      on: r.id == t.rider_id,
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
    Enum.reduce(filters, query, fn filter, q -> apply_filter(filter, q, filters) end)
  end

  @spec apply_filter(Filter.t(), Ecto.Query.t(), list()) :: Ecto.Query.t()
  defp apply_filter(%Filter{type: :name, search: search}, query, _filters) do
    query
    |> where(
      fragment("unaccent(?) ilike unaccent(?)", as(:rider).name, ^"#{search}%") or
        fragment("unaccent(?) ilike unaccent(?)", as(:rider).name, ^"% #{search}%")
    )
  end

  defp apply_filter(%Filter{type: :phone, search: search}, query, _filters) do
    query
    |> where(like(as(:rider).phone, ^"%#{search}%"))
  end

  defp apply_filter(%Filter{type: :name_or_phone, search: search}, query, _filters) do
    query
    |> where(
      fragment("unaccent(?) ilike unaccent(?)", as(:rider).name, ^"#{search}%") or
        fragment("unaccent(?) ilike unaccent(?)", as(:rider).name, ^"% #{search}%") or
        like(as(:rider).phone, ^"%#{search}%")
    )
  end

  defp apply_filter(%Filter{type: :program, id: id}, query, _filters) do
    query
    |> join(:inner, [rider: r], rs in RiderStats,
      on: rs.rider_id == r.id and rs.program_id == ^id
    )
  end

  defp apply_filter(%Filter{type: :tag, search: tag}, query, _filters) do
    query
    |> where(fragment("? = ANY(?)", ^tag, as(:tags).tags))
  end

  defp apply_filter(%Filter{type: :capacity, search: capacity}, query, _filters) do
    # TODO this may be easier with Ecto.Enum instead of EctoEnum
    {:ok, capacity} = Rider.CapacityEnum.dump(capacity)

    query
    |> where(as(:rider).capacity == ^capacity)
  end

  defp apply_filter(%Filter{type: :active, search: "never"}, query, _filters) do
    query
    |> where(is_nil(as(:latest_campaign).id))
  end

  defp apply_filter(%Filter{type: :active, search: "all_time"}, query, _filters) do
    query
    |> where(not is_nil(as(:latest_campaign).id))
  end

  defp apply_filter(%Filter{type: :active, search: weekday}, query, filters)
       when weekday in @weekday_names do
    day_number = @weekdays[weekday]

    # Check if a time period filter exists (week, month, etc.)
    has_period_filter? =
      Enum.any?(filters, fn f ->
        f.type == :active and f.search in ["week", "month"]
      end)

    # Build aggregated weekday stats subquery (executed once, not per-rider)
    # This replaces the correlated EXISTS subquery for better performance
    weekday_stats_subquery =
      from(c in BikeBrigade.Delivery.Campaign,
        join: cr in "campaigns_riders",
        on: cr.campaign_id == c.id,
        where:
          c.delivery_start > ago(@lookback_period_years, "year") and
            fragment(
              "EXTRACT(ISODOW FROM ? AT TIME ZONE ?) = ?",
              c.delivery_start,
              ^@timezone,
              ^day_number
            ),
        group_by: cr.rider_id,
        select: %{
          rider_id: cr.rider_id,
          delivery_count: count(c.id),
          last_delivery: max(c.delivery_start)
        }
      )

    # LEFT JOIN the aggregated stats and filter based on the joined data
    query =
      query
      |> join(:left, [rider: r], ws in subquery(weekday_stats_subquery),
        on: ws.rider_id == r.id,
        as: :weekday_stats
      )

    if has_period_filter? do
      # Combined with period filter: just check if they have any deliveries on this weekday
      query
      |> where([weekday_stats: ws], not is_nil(ws.rider_id))
    else
      # Solo weekday search: apply volume + recency thresholds
      query
      |> where(
        [weekday_stats: ws],
        ws.delivery_count >= ^@volume_threshold and
          ws.last_delivery > ago(@recency_threshold_months, "month")
      )
    end
  end

  defp apply_filter(%Filter{type: :active, search: period}, query, _filters) do
    query
    |> where(as(:latest_campaign).delivery_start > ago(1, ^period))
  end
end
