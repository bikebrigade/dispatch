defmodule BikeBrigade.ScheduledMessenger do
  use GenServer
  alias BikeBrigade.Messaging
  alias BikeBrigade.Delivery
  alias BikeBrigade.Repo

  require Logger

  # Client

  @name {:via, Horde.Registry, {BikeBrigade.HordeRegistry, __MODULE__}}

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

  # Server (callbacks)

  @impl true
  def init(state) do
    :timer.send_interval(60_000, :send_messages)
    {:ok, state}
  end

  @impl true
  def handle_info(:send_messages, state) do
    Repo.transaction(fn ->
      unsent_messages = Messaging.list_unsent_scheduled_messages_locking()

      for s <- unsent_messages do
        Logger.info("Sending messages for campaign #{s.campaign_id}")

        # We have some non-decoupled preloads in get_campaign so we load it here instead of joining
        # TODO: make this work with joins and preloads where we need things
        c = Delivery.get_campaign(s.campaign_id)
        Delivery.send_campaign_messages(c)

        Repo.delete(s)
      end
    end)

    {:noreply, state}
  end
end
