defmodule BikeBrigade.ScheduledMessenger do
  use GenServer
  alias BikeBrigade.Messaging
  alias BikeBrigade.Delivery
  alias Ecto.Multi

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
    for m <- Messaging.list_unsent_scheduled_messages() do
      # TODO join this in
      c = Delivery.get_campaign(m.campaign_id)
      # TODO make this a proper multi
      # the delivery code isnt referencing the right repo :(
      Multi.new()
      |> Multi.run(:send_messges, fn _repo, _changes ->
        Logger.info("Sending messages for campaign #{c.id}")
        Delivery.send_campaign_messages(c)
      end)
      |> Multi.delete(:delete_schedule, m)
      |> BikeBrigade.Repo.transaction()
    end

    {:noreply, state}
  end
end
