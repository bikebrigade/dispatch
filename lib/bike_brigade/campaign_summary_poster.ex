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
    Slack.Operations.notify_missing_channel(campaign)
  end

  defp do_post_summary(campaign, channel_id) do
    summary = prepare_summary(campaign)

    case get_or_create_record(campaign.id, channel_id, summary) do
      {:ok, %{id: nil}} ->
        handle_existing_record(campaign.id, channel_id, summary)

      {:ok, record} ->
        send_and_mark_sent(record, channel_id, summary)

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp prepare_summary(campaign) do
    {_riders, tasks} = Delivery.campaign_riders_and_tasks(campaign)
    Enum.into(tasks, CampaignDeliverySummary.new(campaign))
  end

  defp get_or_create_record(campaign_id, channel_id, summary) do
    %SlackCampaignSummaryMessage{}
    |> SlackCampaignSummaryMessage.changeset(%{
      campaign_id: campaign_id,
      slack_channel_id: channel_id,
      raw_message: inspect(summary)
    })
    |> Repo.insert(on_conflict: :nothing, conflict_target: :campaign_id)
  end

  defp handle_existing_record(campaign_id, channel_id, summary) do
    record = Repo.get_by!(SlackCampaignSummaryMessage, campaign_id: campaign_id)

    if is_nil(record.sent_at) do
      send_and_mark_sent(record, channel_id, summary)
    else
      {:ok, :already_exists}
    end
  end

  defp send_and_mark_sent(record, channel_id, summary) do
    case send_to_slack(channel_id, summary) do
      :ok ->
        mark_as_sent(record)

      {:error, reason} ->
        Logger.error("Failed to send Slack summary for campaign #{record.campaign_id}: #{reason}")
        {:ok, record}
    end
  end

  defp send_to_slack(channel_id, summary) do
    Slack.CampaignSummarySender.send_summary(channel_id, summary)
    :ok
  rescue
    e -> {:error, Exception.message(e)}
  end

  defp mark_as_sent(record) do
    record
    |> SlackCampaignSummaryMessage.changeset(%{sent_at: DateTime.utc_now()})
    |> Repo.update()
  end
end
