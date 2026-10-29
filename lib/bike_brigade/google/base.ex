defmodule BikeBrigade.Google do
  @scopes [
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/drive"
  ]

  @doc """
  A `Req` request authorized against Google APIs.

  The token comes from Goth unless `:token` is configured (as in tests).
  """
  def request(opts \\ []) do
    with {:ok, token} <- token() do
      {:ok, Req.new([auth: {:bearer, token}] ++ req_options() ++ opts)}
    end
  end

  @doc """
  Extra `Req` options for requests made by the Google modules.

  Tests use this to route requests to a `Req.Test` stub.
  """
  def req_options do
    Application.get_env(:bike_brigade, __MODULE__, [])
    |> Keyword.get(:req_options, [])
  end

  defp token do
    case Application.get_env(:bike_brigade, __MODULE__, []) |> Keyword.get(:token) do
      nil ->
        with {:ok, token} <- Goth.fetch(__MODULE__), do: {:ok, token.token}

      token ->
        {:ok, token}
    end
  end

  def append_child_spec(children) do
    config = Application.get_env(:bike_brigade, __MODULE__, [])
    credentials = config |> Keyword.get(:credentials)

    children ++ do_append(credentials, config[:start])
  end

  # N.B.: will start given any other value than `false`
  # `nil` indicates we should startup the Goth server
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
        {:ok, credentials} ->
          credentials

        {:error, %Jason.DecodeError{data: base64}} ->
          base64
          |> Base.decode64!()
          |> Jason.decode!()
      end

    {:service_account, credentials, scopes: @scopes}
  end
end
