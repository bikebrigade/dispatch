defmodule BikeBrigade.CampaignSummaryPoster do
  require Logger

  alias BikeBrigade.Repo
  alias BikeBrigade.Delivery
  alias BikeBrigade.Delivery.CampaignDeliverySummary
  alias BikeBrigade.Messaging.SlackCampaignSummaryMessage
  use BikeBrigade.SingleGlobalGenServer, initial_state: %{}

  @check_interval :timer.minutes(15)

  @impl GenServer
  def init(state) do
    schedule_next_check()
    {:ok, state}
  end

  @impl GenServer
  def handle_info(:post_summary, state) do
    Logger.info("Campaign summary scheduler running...")
    now = NaiveDateTime.utc_now()
    from_datetime = NaiveDateTime.add(now, -75, :minute)
    to_datetime = NaiveDateTime.add(now, -60, :minute)

    ended_campaigns = Delivery.list_campaigns_ended_between(from_datetime, to_datetime)

    Enum.each(ended_campaigns, &post_summary_for_campaign/1)

    schedule_next_check()
    {:noreply, state}
  end

  defp schedule_next_check() do
    Process.send_after(self(), :post_summary, @check_interval)
  end

  def post_summary_for_campaign(campaign) do
    campaign = Repo.preload(campaign, :program)
    {_riders, tasks} = Delivery.campaign_riders_and_tasks(campaign)

    summary = tasks |> Enum.into(CampaignDeliverySummary.new(campaign)) |> Map.from_struct()

    %SlackCampaignSummaryMessage{}
    |> SlackCampaignSummaryMessage.changeset(%{
      campaign_id: campaign.id,
      slack_channel_id: campaign.program.slack_channel_id,
      raw_message: inspect(summary)
    })
    |> Repo.insert(on_conflict: :nothing, conflict_target: :campaign_id)
    |> case do
      {:ok, %{id: nil}} -> {:ok, :already_exists}
      {:ok, record} -> {:ok, record}
      {:error, changeset} -> {:error, changeset}
    end
  end
end
