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
end
