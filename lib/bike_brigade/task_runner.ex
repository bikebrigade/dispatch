defmodule BikeBrigade.TaskRunner do
  import BikeBrigade.Utils, only: [get_config: 1]
  alias BikeBrigade.Tasks.{MailchimpImporter, MailchimpAttributesSync}

  use BikeBrigade.SingleGlobalGenServer, initial_state: %{}

  def append_child_spec(children) do
    config = Application.get_env(:bike_brigade, __MODULE__)

    if config[:start] do
      children ++ [{__MODULE__, []}]
    else
      children
    end
  end

  @impl GenServer
  def init(state) do
    schedule_work()
    {:ok, state}
  end

  @impl GenServer
  def handle_info(:run_importers, state) do
    honeybadger_checkin()
    # TODO let the task decide how often to run itself
    MailchimpImporter.sync_riders()
    MailchimpAttributesSync.sync_mailchimp_attributes()

    schedule_work()
    {:noreply, state}
  end

  defp schedule_work() do
    # In 10 minutes
    Process.send_after(self(), :run_importers, 10 * 60 * 1000)
  end

  defp honeybadger_checkin() do
    checkin_url = get_config(:checkin_url)

    if checkin_url do
      HTTPoison.get(checkin_url)
    end
  end
end
