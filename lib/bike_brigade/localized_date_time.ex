defmodule BikeBrigade.LocalizedDateTime do
  @timezone "America/Toronto"

  def localize(%DateTime{} = datetime) do
    DateTime.shift_zone!(datetime, @timezone)
  end

  def localize(%NaiveDateTime{} = datetime) do
    DateTime.from_naive!(datetime, @timezone)
  end

  def now() do
    DateTime.utc_now()
    |> localize()
  end

  def today() do
    DateTime.utc_now()
    |> to_date()
  end

  def new(date, time) do
    DateTime.new(date, time, @timezone)
  end

  def new!(date, time) do
    DateTime.new!(date, time, @timezone)
  end

  def to_date(datetime) do
    localize(datetime)
    |> DateTime.to_date()
  end

  def to_time(datetime) do
    localize(datetime)
    |> DateTime.to_time()
  end

  def to_time!(datetime) do
    localize(datetime)
    |> DateTime.to_time()
  end

  def format_date(datetime, format_string \\ "%b %-d, %Y") do
    datetime
    |> to_date()
    |> Calendar.strftime(format_string)
  end
end
