defmodule BikeBrigade.LocalizedDateTime do
  defp timezone() do
    Application.get_env(:bike_brigade, __MODULE__)[:timezone]
  end

  def localize(%DateTime{} = datetime) do
    DateTime.shift_zone!(datetime, timezone())
  end

  def localize(%NaiveDateTime{} = datetime) do
    DateTime.from_naive!(datetime, timezone())
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
    DateTime.new(date, time, timezone())
  end

  def new!(date, time) do
    DateTime.new!(date, time, timezone())
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
end
