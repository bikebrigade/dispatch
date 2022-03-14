defmodule BikeBrigade.ScheduledMessenger do
  alias BikeBrigade.Messaging
  alias BikeBrigade.Delivery
  alias BikeBrigade.Repo
  require Logger

  use BikeBrigade.SingleGlobalGenServer, initial_state: %{}

  @impl GenServer
  def init(state) do
    :timer.send_interval(60_000, :send_messages)
    {:ok, state}
  end

  @impl GenServer
  def handle_info(:send_messages, state) do
    Repo.transaction(
      fn ->
        unsent_messages =
          Messaging.list_unsent_scheduled_messages(lock: true, log: false)
          |> Repo.preload(:campaign)

        for s <- unsent_messages do
          Logger.info("Sending scheduled messages for campaign #{s.campaign_id}")

          Delivery.send_campaign_messages(s.campaign)

          Repo.delete(s)
        end
      end,
      log: false
    )

    {:noreply, state}
  end
end
