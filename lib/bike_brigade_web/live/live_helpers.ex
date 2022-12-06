defmodule BikeBrigadeWeb.LiveHelpers do
  alias BikeBrigade.Locations.Location
  alias BikeBrigade.LocalizedDateTime

  def gravatar(email) when is_binary(email) do
    hash =
      email
      |> String.trim()
      |> String.downcase()
      |> :erlang.md5()
      |> Base.encode16(case: :lower)

    "https://www.gravatar.com/avatar/#{hash}?s=150&d=identicon"
  end

  def gravatar(nil), do: gravatar("")

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

  def address(%Location{} = location) do
    "#{location}"
  end

  def address(nil), do: "Unknown"

  def phone(%{} = struct) do
    Map.get(struct, :phone, "Unknown")
  end

  def phone(nil), do: "Unknown"

  def email(%{} = struct) do
    Map.get(struct, :email, "Unknown")
  end

  def email(nil), do: "Unknown"

  def pronouns(%{} = struct) do
    Map.get(struct, :phone, "Unknown")
  end

  def pronouns(nil), do: "Unknown"

  def coords(%Location{coords: coords}), do: coords
  def coords(nil), do: %Geo.Point{}

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
end
