defmodule BikeBrigade.Google do
  @scopes [
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/drive"
  ]

  def append_child_spec(children) do
    config = Application.get_env(:bike_brigade, __MODULE__, [])
    credentials = config |> Keyword.get(:credentials)

    children ++ do_append(credentials, config[:start])
  end

  defp do_append(nil, _), do: []
  defp do_append(_credentials, false), do: []

  defp do_append(credentials, _) do
    spec = {Goth, name: BikeBrigade.Google, source: source(credentials)}
    [spec]
  end

  defp source(credentials) do
    credentials =
      case credentials
           |> Jason.decode() do
        {:ok, credentials} -> credentials
        {:error, _err} -> nil
      end

    {:service_account, credentials, scopes: @scopes}
  end
end
