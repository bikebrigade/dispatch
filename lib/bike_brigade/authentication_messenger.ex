defmodule BikeBrigade.AuthenticationMessenger do
  use GenServer

  import BikeBrigade.Utils

  alias BikeBrigade.Messaging
  alias BikeBrigade.SmsService

  require Logger

  @name {:via, Horde.Registry, {BikeBrigade.HordeRegistry, __MODULE__}}

  # Client

  def start_link([]) do
    # When we are in non-distributed mode start us using Horde
    # TODO: this + @name can be abstracted to a Singleton Genserver or the like
    Horde.DynamicSupervisor.start_child(
      BikeBrigade.HordeSupervisor,
      {__MODULE__, distributed: true}
    )

    # Ignore since this is called from the main supervisor
    :ignore
  end

  def start_link(distributed: true) do
    case GenServer.start_link(__MODULE__, %{}, name: @name) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.info("#{inspect(__MODULE__)}: already started at #{inspect(pid)}, returning :ignore")
        :ignore
    end
  end

  def generate_token(phone), do: generate_token(@name, phone)

  def generate_token(pid, phone) do
    GenServer.call(pid, {:generate_token, phone})
  end

  def validate_token(phone, token_attempt), do: validate_token(@name, phone, token_attempt)

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

      {:error, error} ->
        {:reply, {:error, "Twilio error: #{error}"}, state}
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

  defp send_message(phone, token) do
    msg = [
      from: Messaging.outbound_number(),
      to: phone,
      body: "Your BikeBrigade access code is #{token}."
    ]

    SmsService.send_sms(msg)
  end
end
