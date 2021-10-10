defmodule BikeBrigade.SlackApi do
  use BikeBrigade.Adapter, :slack

  @type url :: String.t()
  @type body :: String.t()
  @type headers :: list({String.t(), String.t()})

  @callback post!(url, body, headers) :: :ok

  @headers [{"content-type", "application/json"}]

  defmodule Error do
    defexception [:message, :response]

    def exception(%{} = response) do
      %__MODULE__{message: "SlackApi call failed: #{inspect(response)}", response: response}
    end
  end

  @doc """
  Send a message to an incoming Slack webhook
  """
  def send_webook(body, headers \\ @headers, opts \\ []) do
    url = Keyword.get(opts, :url, webhook_url())
    @slack.post!(url, body, headers)
  end

  defp webhook_url() do
    BikeBrigade.Utils.fetch_env!(:slack, :webhook_url)
  end
end
