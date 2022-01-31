defmodule BikeBrigade.SlackApi.FakeSlack do
  use GenServer

  require Logger

  alias __MODULE__, as: State

  defstruct [:token, calls: []]

  @behaviour BikeBrigade.SlackApi

  def start_link(opts \\ []) do
    opts =
      case Keyword.get(opts, :name, :default) do
        :default -> [name: __MODULE__]
        nil -> []
        name -> [name: name]
      end

    expected_token = BikeBrigade.Utils.fetch_env!(:slack, :token)
    state = %State{token: expected_token}
    GenServer.start_link(__MODULE__, state, opts)
  end

  def post!(url, body, headers, server \\ __MODULE__) do
    GenServer.call(server, {:post, url, body, headers})
  end

  def get_last_call(server \\ __MODULE__) do
    GenServer.call(server, :get_last_call)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call({:post, url, body, headers}, _from, state) do
    Logger.info("""
    Received FakeSlack call:
             method: POST
             url: #{url}
             body: #{body}
             headers: #{inspect(headers)}"
    """)

    call = %{method: :post, url: url, body: body, headers: headers}
    calls = [call | state.calls]
    {:reply, :ok, %{state | calls: calls}}
  end

  def handle_call(:get_last_call, _from, state) do
    {:reply, state.calls |> hd(), state}
  end
end
