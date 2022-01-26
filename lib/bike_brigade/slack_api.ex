defmodule BikeBrigade.SlackApi do
  use BikeBrigade.Adapter, :slack

  @type url :: String.t()
  @type body :: String.t()
  @type headers :: list({String.t(), String.t()})

  @callback post!(url, body, headers) :: :ok

  @token BikeBrigade.Utils.fetch_env!(:slack, :token)
  @headers [
    {"content-type", "application/json"},
    {"authorization", "Bearer #{@token}"},
    {"charset", "utf-8"}
  ]
  @url "https://slack.com/api/chat.postMessage"

  defmodule Error do
    defexception [:message, :response]

    def exception(%{} = response) do
      %__MODULE__{message: "SlackApi call failed: #{inspect(response)}", response: response}
    end
  end

  def post_message(body) do
    @slack.post!(@url, body, @headers)
  end
end
