defmodule BikeBrigade.ScheduledMessenger do
  use GenServer
  alias BikeBrigade.Messaging
  alias BikeBrigade.Delivery
  alias Ecto.Multi

  require Logger

  # Client

  def start_link(opts \\ []) do
    opts = Keyword.put_new(opts, :name, __MODULE__)
    GenServer.start_link(opts[:name], %{}, opts)
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
