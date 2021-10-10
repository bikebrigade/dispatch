defmodule BikeBrigade.SlackApi.Http do
  alias BikeBrigade.SlackApi

  @behaviour SlackApi

  def post!(url, body, headers) do
    case HTTPoison.post!(url, body, headers) do
      %{status_code: 200} ->
        :ok

      response ->
        raise SlackApi.Error, response
    end
  end
end
