defmodule BikeBrigade.AuthenticationMessenger do
  use GenServer

  import BikeBrigade.Utils

  alias BikeBrigade.Messaging
  alias BikeBrigade.SmsService

  require Logger

  # Client

  def start_link(opts \\ []) do
    opts = Keyword.put_new(opts, :name, __MODULE__)
    GenServer.start_link(opts[:name], %{}, opts)
  end

  def generate_token(phone), do: generate_token(__MODULE__, phone)

  def generate_token(pid, phone) do
    GenServer.call(pid, {:generate_token, phone})
  end

  def validate_token(phone, token_attempt), do: validate_token(__MODULE__, phone, token_attempt)

  def validate_token(pid, phone, token_attempt) when is_binary(token_attempt) do
    try do
      validate_token(pid, phone, String.to_integer(token_attempt))
    rescue
      # String.to_integer throws when the streing is invalid
      ArgumentError -> {:error, :token_invalid}
    end
  end

  def validate_token(pid, phone, token_attempt) do
    GenServer.call(pid, {:validate_token, phone, token_attempt})
  end

  # Server (callbacks)

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:generate_token, phone}, _from, state) do
    # Generate a 6 digit token
    token = :rand.uniform(899_999) + 100_000

    case send_message(phone, token) do
      {:ok, _msg} ->
        Process.send_after(self(), {:expire, phone}, 60000)
        {:reply, :ok, Map.put(state, phone, token)}

      {:error, err, _code} ->
        {:reply, {:error, "Twilio error: #{Map.get(err, "message", "unknown")}"}, state}
    end
  end

  @impl true
  def handle_call({:validate_token, phone, token_attempt}, _from, state) do
    # TODO refactor
    if !dev?() do
      unless Map.has_key?(state, phone) do
        {:reply, {:error, :token_expired}, state}
      else
        if token_attempt == Map.get(state, phone) do
          {:reply, :ok, state}
        else
          {:reply, {:error, :token_invalid}, state}
        end
      end
    else
      {:reply, :ok, state}
    end
  end

  @impl true
  def handle_info({:expire, phone}, state) do
    {:noreply, Map.delete(state, phone)}
  end

  # TODO move this to a module that wraps extwilio
  defp send_message(phone, token) do
    msg = [
      from: Messaging.outbound_number(),
      to: phone,
      body: "Your BikeBrigade access code is #{token}."
    ]

    SmsService.send_sms(msg)
  end
end
