defmodule BikeBrigadeWeb.LiveHelpers do
  alias BikeBrigade.Locations.Location
  alias BikeBrigade.LocalizedDateTime

  def gravatar(nil) do
    ""
  end
  def gravatar(email) do
    hash =
      email
      |> String.trim()
      |> String.downcase()
      |> :erlang.md5()
      |> Base.encode16(case: :lower)

    "https://www.gravatar.com/avatar/#{hash}?s=150&d=identicon"
  end

  def format_date(datetime), do: format_date(datetime, "%b %-d, %Y")

  def format_date(%DateTime{} = datetime, format) do
    LocalizedDateTime.localize(datetime)
    |> Calendar.strftime(format)
  end

  def format_date(%Date{} = date, format) do
    Calendar.strftime(date, format)
  end

  def datetime(datetime) do
    LocalizedDateTime.localize(datetime)
    |> Calendar.strftime("%x %-I:%M%p %Z")
  end

  def time_interval(start_datetime, end_datetime) do
    if start_datetime == end_datetime do
      LocalizedDateTime.localize(start_datetime)
      |> Calendar.strftime("%-I:%M%p")
    else
      s =
        LocalizedDateTime.localize(start_datetime)
        |> Calendar.strftime("%-I:%M")

      e =
        LocalizedDateTime.localize(end_datetime)
        |> Calendar.strftime("%-I:%M%p")

      "#{s}-#{e}"
    end
  end

  def lat(%Geo.Point{coordinates: {_lng, lat}}), do: lat
  def lat(%Location{coords: coords}), do: lat(coords)

  def lat(_), do: nil

  def lng(%Geo.Point{coordinates: {lng, _lat}}), do: lng
  def lng(%Location{coords: coords}), do: lng(coords)
  def lng(_), do: nil

  @doc """
  Round distance in metres to nearest .1km
  """
  def round_distance(metres) do
    round(metres / 100) / 10
  end

  @doc """
  Render content preserving spacing and phone numbers as links
  """
  def render_raw(content) when is_binary(content) do
    content
    |> Linkify.link(phone: true, class: "link break-all", new_window: true)
    |> Phoenix.HTML.raw()
  end

  def render_raw(nil), do: ""

  def favicon_path(conn) do
    if BikeBrigade.Utils.dev?() do
      BikeBrigadeWeb.Router.Helpers.static_path(conn, "/favicon_dev.png")
    else
      BikeBrigadeWeb.Router.Helpers.static_path(conn, "/favicon.png")
    end
  end
end
