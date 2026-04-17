defmodule BikeBrigade.CampaignSummaryPoster do
  @moduledoc """
  A GenServer that automatically posts campaign delivery summaries to Slack.

  This process runs as a singleton across the cluster and checks every 15 minutes
  for campaigns that ended between 60-75 minutes ago. For each ended campaign,
  it generates a delivery summary and posts it to the program's configured Slack channel.

  Summaries are tracked in the database to prevent duplicate postings.
  """

  require Logger

  alias BikeBrigade.Repo
  alias BikeBrigade.Delivery
  alias BikeBrigade.Delivery.CampaignDeliverySummary
  alias BikeBrigade.Messaging.Slack
  alias BikeBrigade.Messaging.SlackCampaignSummary
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

  @doc """
  Posts a delivery summary for the given campaign to Slack.

  Preloads the campaign's program to get the Slack channel ID, generates a
  delivery summary from the campaign's tasks, and sends it to Slack.

  Returns:
    - `{:ok, :already_exists}` - if a summary was already posted for this campaign
    - `{:ok, record}` - if the summary was successfully posted
    - `{:error, changeset}` - if there was a database error
  """
  def post_summary_for_campaign(campaign) do
    campaign = Repo.preload(campaign, :program)
    do_post_summary(campaign, campaign.program.slack_channel_id)
  end

  defp do_post_summary(campaign, nil) do
    Logger.warning("Skipping campaign #{campaign.id}: no Slack channel configured for program")
    Slack.Operations.notify_campaign_error(campaign, "No Slack channel configured")
  end

  defp do_post_summary(campaign, channel_id) do
    {_riders, tasks} = Delivery.campaign_riders_and_tasks(campaign)
    summary = Enum.into(tasks, CampaignDeliverySummary.new(campaign))

    with {:ok, record} <- find_or_create_record(campaign.id, channel_id, summary),
         :ok <- send_to_slack(channel_id, summary) do
      record
      |> SlackCampaignSummary.changeset(%{sent_at: DateTime.utc_now()})
      |> Repo.update()
    else
      {:error, :already_sent} ->
        Logger.debug("Summary already sent for campaign #{campaign.id}")

      {:error, _reason} ->
        Slack.Operations.notify_campaign_error(campaign, "Failed to send summary")
    end
  end

  defp find_or_create_record(campaign_id, channel_id, summary) do
    attrs = %{
      campaign_id: campaign_id,
      slack_channel_id: channel_id,
      raw_message: inspect(summary)
    }

    case Repo.insert(SlackCampaignSummary.changeset(%SlackCampaignSummary{}, attrs),
           on_conflict: :nothing,
           conflict_target: :campaign_id
         ) do
      {:ok, %{id: nil}} ->
        # Record already exists - check if already sent
        record = Repo.get_by!(SlackCampaignSummary, campaign_id: campaign_id)
        if record.sent_at, do: {:error, :already_sent}, else: {:ok, record}

      {:ok, record} ->
        {:ok, record}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp send_to_slack(channel_id, summary) do
    Slack.CampaignSummarySender.send_summary(channel_id, summary)
    :ok
  rescue
    e ->
      Logger.error("Failed to send Slack summary: #{Exception.message(e)}")
      {:error, e}
  end
end
