defmodule BikeBrigade.DataMigrations.UpdatePickupWindows do

  # This has been superceded by the live notebook at notebooks/20210928_update_missing_dates.livemd
  import Ecto.Query, warn: false

  alias BikeBrigade.Delivery
  alias BikeBrigade.Delivery.Campaign
  alias BikeBrigade.LocalizedDateTime

  require Logger

  def run() do
    q =
      from c in Campaign,
        where: is_nil(c.delivery_start) and not is_nil(c.pickup_window)

    campaigns = BikeBrigade.Repo.all(q)

    for c <- campaigns do
      if window = guess_window(c.pickup_window) do
        {start_time, end_time} = window

        delivery_start = LocalizedDateTime.new!(c.delivery_date, start_time)
        delivery_end = LocalizedDateTime.new!(c.delivery_date, end_time)

        Delivery.update_campaign(c, %{delivery_start: delivery_start, delivery_end: delivery_end})
      else
        Logger.info("Unable to update #{c.id} - #{c.name}")
      end
    end
  end

  def guess_window(window) do
    case String.split(window, "-") do
      [s] ->
        if time = parse_time(s) do
          {time, time}
        end

      [s, e] ->
        start_time = parse_time(s)
        end_time = parse_time(e)

        if start_time && end_time do
          {start_time, end_time}
        end
    end
  end

  def parse_time(timestr) do
    am_or_pm =
      cond do
        Regex.match?(~r/am/i, timestr) -> :am
        Regex.match?(~r/pm/i, timestr) -> :pm
        true -> nil
      end

    case {parse_hour_minute(timestr), am_or_pm} do
      {{12, minute}, :am} -> Time.new!(0, minute, 0)
      {{hour, minute}, :am} -> Time.new!(hour, minute, 0)
      {{12, minute}, :pm} -> Time.new!(12, minute, 0)
      {{hour, minute}, :pm} -> Time.new!(hour + 12, minute, 0)
      {{hour, minute}, nil} when hour < 8 -> Time.new!(hour + 12, minute, 0)
      {{hour, minute}, nil} when hour >= 8 -> Time.new!(hour, minute, 0)
      _ -> nil
    end
  end

  def parse_hour_minute(timestr) do
    timestr = String.replace(timestr, ~r/[^\d]/, "")

    cond do
      c = Regex.run(~r/^(\d\d?)$/i, timestr, capture: :all_but_first) ->
        [h] = c
        hour = String.to_integer(h)
        {hour, 0}

      c = Regex.run(~r/^(\d\d?)(\d\d)$/i, timestr, capture: :all_but_first) ->
        [h, m] = c
        hour = String.to_integer(h)
        minute = String.to_integer(m)
        {hour, minute}

      true ->
        nil
    end
  end
end
