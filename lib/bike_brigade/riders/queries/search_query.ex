defmodule BikeBrigade.Riders.Queries.SearchQuery do
  import Ecto.Query

  alias BikeBrigade.Repo

  alias BikeBrigade.Riders.{Rider, Tag}
  alias BikeBrigade.QueryContext

  def apply_filter({:name, search}, where) do
    dynamic(
      (^where and ilike(as(:rider).name, ^"#{search}%")) or
        ilike(as(:rider).name, ^"% #{search}%")
    )
  end

  def apply_filter({:tag, tag}, where) do
    dynamic(^where and fragment("? = ANY(?)", ^tag, as(:tags).tags))
  end

  def apply_filter({:capacity, capacity}, where) do
    # TODO this may be easier with Ecto.Enum instead of EctoEnum
    {:ok, capacity} = Rider.CapacityEnum.dump(capacity)
    dynamic(^where and as(:rider).capacity == ^capacity)
  end

  def apply_filter({:active, :never}, where) do
    dynamic(^where and is_nil(as(:latest_campaign).id))
  end

  def apply_filter({:active, period}, where) do
    dynamic(^where and as(:latest_campaign).delivery_start > ago(1, ^period))
  end

  def apply_sort(%QueryContext.Sort{field: field, order: order}) when field in [:name, :capacity] do
    [{order, field}]
  end

  def apply_sort(%QueryContext.Sort{field: :last_active, order: order}) do
    ["#{order}_nulls_last": dynamic(as(:latest_campaign).delivery_start), asc: :name]
  end

  def base_query() do
    tags_query =
      from t in Tag,
        join: r in assoc(t, :riders),
        where: r.id == parent_as(:rider).id,
        select: %{tags: fragment("array_agg(?)", t.name)}

    from r in Rider,
      as: :rider,
      left_lateral_join: t in subquery(tags_query),
      as: :tags,
      left_join: l in assoc(r, :latest_campaign),
      as: :latest_campaign
  end

  def filter(query, filters) do
    query
    |> where(^Enum.reduce(filters, dynamic(true), &apply_filter/2))
  end

  def sort(query, sort) do
    query
    |> order_by(^apply_sort(sort))
  end

  def paginate(query, nil) do
    query
  end

  def paginate(query, %QueryContext.Pager{offset: offset, limit: limit}) do
    query
    |> offset(^offset)
    |> limit(^limit)
  end

  def run(
        %QueryContext{filters: filters, sort: sort, pager: pager},
        options \\ [total: false]
      ) do
    query =
      base_query()
      |> filter(filters)
      |> sort(sort)
      |> paginate(pager)


    riders = Repo.all(query)

    # some half-baked pagination
    total =
      if Keyword.get(options, :total) do
        query
        |> exclude(:preload)
        |> exclude(:order_by)
        |> exclude(:select)
        |> exclude(:limit)
        |> exclude(:offset)
        |> select(count())
        |> Repo.one()
      end

    {riders, total}
  end
end
