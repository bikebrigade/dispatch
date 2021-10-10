defmodule BikeBrigade.SmsService.FakeSmsService do
  use GenServer

  require Logger

  alias BikeBrigade.SmsService
  alias BikeBrigade.Utils

  @behaviour SmsService

  @delay_before_callback 1500

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl GenServer
  def init(messages_sent) do
    {:ok, messages_sent}
  end

  @impl SmsService
  def send_sms(message) do
    case GenServer.call(__MODULE__, {:send_sms, message}) do
      {:ok, result} ->
        enqueue_callback(__MODULE__, message, result)
        {:ok, result}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl SmsService
  def request_valid?(_url, _params, _signature) do
    true
  end

  def last_message() do
    GenServer.call(__MODULE__, :last_message)
  end

  @impl GenServer
  def handle_call({:send_sms, message}, _from, messages_sent) do
    Logger.info("SMS Not Sent. FakeSmsService#send_sms(#{inspect(message)})")

    message_id =
      "BB#{Ecto.UUID.generate()}"
      |> String.replace("-", "")
      |> String.slice(0..34)

    status = "queued"

    messages_sent = [message | messages_sent]
    {:reply, {:ok, %{status: status, sid: message_id}}, messages_sent}
  end

  def handle_call(:last_message, _from, messages_sent) do
    {:reply, messages_sent |> hd(), messages_sent}
  end

  @impl GenServer
  def handle_info({:send_callback, url, sid, status}, messages_sent) do
    send_status_callback(url, sid, status)
    {:noreply, messages_sent}
  end

  defp enqueue_callback(pid, message, result) do
    case Keyword.get(message, :statusCallback) do
      url when is_binary(url) ->
        %{sid: message_id} = result
        msg = {:send_callback, url, message_id, "delivered"}

        unless Utils.test?() do
          Process.send_after(pid, msg, @delay_before_callback)
        end

      nil ->
        :ok
    end
  end

  defp send_status_callback(url, message_id, status) do
    body =
      %{"SmsSid" => message_id, "SmsStatus" => status}
      |> Jason.encode!()

    headers = [
      {"content-type", "application/json"}
    ]

    HTTPoison.post!(url, body, headers)
  end
end
