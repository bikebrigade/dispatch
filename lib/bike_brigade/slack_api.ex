defmodule BikeBrigade.SlackApi do
  use BikeBrigade.Adapter, :slack

  @type url :: String.t()
  @type body :: String.t()
  @type headers :: list({String.t(), String.t()})

  @callback post!(url, body, headers) :: :ok

  @headers [
    {"content-type", "application/json"},
    {"charset", "utf-8"}
  ]
  @url "https://slack.com/api/chat.postMessage"

  defmodule Error do
    defexception [:message, :response]

    def exception(%{} = response) do
      %__MODULE__{message: "SlackApi call failed: #{inspect(response)}", response: response}
    end
  end

  def post_message!(body) do
    headers = [auth_header() | @headers]
    @slack.post!(@url, body, headers)
  end

  defp auth_header() do
    token = BikeBrigade.Utils.fetch_env!(:slack, :token)
    {"authorization", "Bearer #{token}"}
  end
end
