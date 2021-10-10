defmodule BikeBrigade.Importers.Runner do
  use GenServer

  import BikeBrigade.Utils, only: [get_config: 1]

  alias BikeBrigade.Importers.MailchimpImporter

  def start_link([]) do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    schedule_work()
    {:ok, state}
  end

  def handle_info(:run_importers, state) do
    honeybadger_checkin()
    MailchimpImporter.sync_riders()

    schedule_work()
    {:noreply, state}
  end

  defp schedule_work() do
    Process.send_after(self(), :run_importers, 10 * 60 * 1000) # In 10 minutes
  end

  defp honeybadger_checkin() do
    checkin_url = get_config(:checkin_url)
    if checkin_url do
      HTTPoison.get(checkin_url)
    end
  end
end
