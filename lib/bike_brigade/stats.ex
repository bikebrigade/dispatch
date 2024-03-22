defmodule BikeBrigade.Stats do
  import Ecto.Query, warn: false
  import Geo.PostGIS, only: [st_distance: 2]

  alias BikeBrigade.Repo
  alias BikeBrigade.Riders.Rider
  alias BikeBrigade.Delivery.Task

  alias BikeBrigade.LocalizedDateTime

  defmodule RiderStat do
    @derive {Phoenix.Param, key: :rider}
    defstruct [:rider, :campaigns, :deliveries, :distance]
  end

  def rider_counts() do
    total = Repo.aggregate(Rider, :count)
    active = Repo.one(from t in Task, select: count(t.assigned_rider_id, :distinct))
    {total, active}
  end

  defmacro date_trunc(part, field) do
    quote do
      fragment("date_trunc(?,?)", unquote(part), unquote(field))
    end
  end

  def rider_stats(period \\ :week) when period in [:day, :week, :month] do
    order_by =
      case period do
        :day ->
          dynamic(date_trunc("day", as(:campaign).delivery_start))

        :week ->
          dynamic(
            date_trunc(
              "week",
              as(:campaign).delivery_start
            )
          )

        :month ->
          dynamic(
            date_trunc(
              "month",
              as(:campaign).delivery_start
            )
          )
      end

    row_counts =
      from t in Task,
        where: not is_nil(t.assigned_rider_id),
        join: c in assoc(t, :campaign),
        as: :campaign,
        windows: [
          periods: [
            partition_by: t.assigned_rider_id,
            order_by: ^order_by
          ]
        ],
        select: %{
          rider_id: t.assigned_rider_id,
          row_number: over(row_number(), :periods)
        },
        group_by: fragment("period, rider_id")

    # can't use a dynamic here because it's in a select
    row_counts =
      case period do
        :day ->
          row_counts
          |> select_merge(%{
            period:
              date_trunc(
                "day",
                as(:campaign).delivery_start
              )
          })

        :week ->
          row_counts
          |> select_merge(%{
            period:
              date_trunc(
                "week",
                as(:campaign).delivery_start
              )
          })

        :month ->
          row_counts
          |> select_merge(%{
            period:
              date_trunc(
                "month",
                as(:campaign).delivery_start
              )
          })
      end

    within_past_year =
      dynamic(as(:row_counts).period > fragment("CURRENT_DATE - interval '1 year'"))

    within_past_month =
      dynamic(as(:row_counts).period > fragment("CURRENT_DATE - interval '1 month'"))

    where =
      case period do
        :day ->
          dynamic(
            date_trunc("day", as(:row_counts).period) <
              date_trunc("day", fragment("CURRENT_DATE")) and ^within_past_month
          )

        :week ->
          dynamic(
            date_trunc("week", as(:row_counts).period) <
              date_trunc("week", fragment("CURRENT_DATE")) and ^within_past_year
          )

        :month ->
          dynamic(
            date_trunc("month", as(:row_counts).period) <
              date_trunc("month", fragment("CURRENT_DATE")) and ^within_past_year
          )
      end

    query =
      from rc in subquery(row_counts),
        as: :row_counts,
        group_by: rc.period,
        order_by: rc.period,
        where: ^where,
        select: {
          rc.period,
          %{
            riders: coalesce(count(rc.rider_id), 0),
            new_riders:
              coalesce(fragment("COUNT(?) FILTER (WHERE ? = 1)", rc.rider_id, rc.row_number), 0),
            returning_riders:
              coalesce(fragment("COUNT(?) FILTER (WHERE ? > 1)", rc.rider_id, rc.row_number), 0)
          }
        }

    Repo.all(query)
  end

  # WITH counts as (SELECT tasks.assigned_rider_id, count(tasks.id) from tasks JOIN campaigns ON tasks.campaign_id = campaigns.id WHERE campaigns.delivery_date > date '2021-04-08' AND tasks.assigned_rider_id IS NOT NULL GROUP BY tasks.assigned_rider_id ORDER BY 2 desc), cum_sum as (SELECT *, SUM(count) OVER (order by count desc, assigned_rider_id) FROM counts) SELECT COUNT(assigned_rider_id) FILTER (WHERE sum <= (SELECT sum(count)*.5 FROM cum_sum)) FROM cum_sum;
  # Use this to find .5 .8 .9

  def rider_leaderboard(
        sort_by,
        sort_order
      )
      when sort_by in [:rider_name, :campaigns, :deliveries, :distance] and
             sort_order in [:desc, :asc] do
    leaderboard_subquery()
    |> make_leaderboard(sort_by, sort_order)
    |> Repo.all()
  end

  def rider_leaderboard(
        sort_by,
        sort_order,
        %Date{} = start_date,
        %Date{} = end_date
      )
      when sort_by in [:rider_name, :campaigns, :deliveries, :distance] and
             sort_order in [:desc, :asc] do
    leaderboard_subquery(start_date, end_date)
    |> make_leaderboard(sort_by, sort_order)
    |> Repo.all()
  end

  # TODO: we're using a custom query here while we also have the RiderStats view
  # The issue is that we can't filter that view by campaign date easily
  # Ideally we'd use the view normally and then custom query if searching by date?
  @base_query from r in Rider,
                join: t in assoc(r, :assigned_tasks),
                join: c in assoc(t, :campaign),
                as: :campaign,
                join: pl in assoc(t, :pickup_location),
                join: dl in assoc(t, :dropoff_location),
                select: %{
                  rider_id: r.id,
                  campaign_id: c.id,
                  task_id: t.id,
                  distance: st_distance(pl.coords, dl.coords)
                }

  defp leaderboard_subquery() do
    from r in @base_query,
      where: as(:campaign).delivery_start <= ^LocalizedDateTime.now()
  end

  defp leaderboard_subquery(%Date{} = start_date, %Date{} = end_date) do
    from r in @base_query,
      where:
        as(:campaign).delivery_start >=
          ^LocalizedDateTime.new!(start_date, ~T[00:00:00]),
      where:
        as(:campaign).delivery_end <=
          ^LocalizedDateTime.new!(end_date, ~T[23:59:59])
  end

  defp make_leaderboard(aggregates_query, sort_by, sort_order) do
    order_by =
      case sort_by do
        :rider_name -> dynamic(as(:rider).name)
        :campaigns -> dynamic(count(as(:aggregate).campaign_id))
        :deliveries -> dynamic(count(as(:aggregate).task_id))
        :distance -> dynamic(sum(as(:aggregate).distance))
      end

    from r in Rider,
      as: :rider,
      join: a in subquery(aggregates_query),
      as: :aggregate,
      on: r.id == a.rider_id,
      group_by: r.id,
      order_by: ^{sort_order, order_by},
      select: %RiderStat{
        rider: r,
        campaigns: count(a.campaign_id, :distinct),
        deliveries: count(a.task_id, :distinct),
        distance: sum(a.distance)
      }
  end

  @doc """
    Stat data for the rider home.
  """
  def home_stats() do
    today = LocalizedDateTime.today()
    week_ago = Date.add(today, -7)

    Repo.one(
      from r in subquery(leaderboard_subquery(week_ago, today)),
        select: %{
          riders: count(r.rider_id, :distinct),
          tasks: count(r.task_id, :distinct),
          campaigns: count(r.campaign_id, :distinct),
          distance: sum(r.distance) #todo(ty): convert to kilometers in memory (there's a util, do it on the frontend),
        }
    )
    |> IO.inspect()
  end
end
