defimpl Phoenix.Param, for: Date do
  def to_param(date), do: Date.to_iso8601(date)
end
