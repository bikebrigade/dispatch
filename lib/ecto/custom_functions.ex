defmodule Ecto.CustomFunctions do
  defmacro coalesce(left, right) do
    quote do
      fragment("coalesce(?, ?)", unquote(left), unquote(right))
    end
  end

  defmacro date(field) do
    quote do
      fragment("date(?)", unquote(field))
    end
  end

  @doc """
  Get the coordinates from a location for use in Ecto queries
  """
  defmacro location_coords(location) do
    quote do
      fragment(
        "ST_GeomFromGeoJSON(? ->> 'coords')",
        unquote(location)
      )
    end
  end
end
