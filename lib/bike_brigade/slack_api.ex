defmodule BikeBrigade.SlackApi do
  use BikeBrigade.Adapter, :slack

  @type url :: String.t()
  @type body :: String.t()
  @type headers :: list({String.t(), String.t()})

  @callback post!(url, body, headers) :: :ok
  @callback get!(url, headers) :: map()

  @headers [
    {"content-type", "application/json"},
    {"charset", "utf-8"}
  ]
  @post_message_url "https://slack.com/api/chat.postMessage"
  @conversations_list_url "https://slack.com/api/conversations.list"

  defmodule Error do
    defexception [:message, :response]

    def exception(%{} = response) do
      %__MODULE__{message: "SlackApi call failed: #{inspect(response)}", response: response}
    end
  end

  def list_channels() do
    headers = [auth_header() | @headers]
    response = adapter().get!(@conversations_list_url, headers)
    response["channels"] || []
  end

  def post_message!(body) do
    headers = [auth_header() | @headers]
    adapter().post!(@post_message_url, body, headers)
  end

  defp auth_header() do
    token = BikeBrigade.Utils.fetch_env!(:slack, :token)
    {"authorization", "Bearer #{token}"}
  end
end
