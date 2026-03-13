defmodule BikeBrigade.CampaignSummaryPoster do
  @moduledoc """
  GenServer that automatically posts campaign summaries to Slack when campaigns end.

  Runs every 15 minutes to check for campaigns that have ended and posts summaries
  to the program's Slack channel.

  ## Behavior

  - Checks for campaigns that ended 60-75 minutes ago (1-hour buffer + 15-minute window)
  - Uses two-phase commit pattern for race-safe deduplication
  - Only posts summaries for campaigns that haven't been claimed (tracked via `campaign_summaries` table)
  - Posts to the program's configured Slack channel

  ## Deduplication Strategy

  Uses atomic transactions to prevent duplicate summaries:
  1. **Phase 1 (Claim)**: Fast database transaction checks and inserts campaign_summaries record
  2. **Phase 2 (Post)**: Slack API call happens outside transaction if claim succeeded

  ## Summary Content

  Each summary includes:
  - Campaign details (program, location, delivery window)
  - Rider and task statistics
  - Delivery completion status
  """

  alias BikeBrigade.Delivery
  alias BikeBrigade.Messaging
  alias BikeBrigade.Repo
  require Logger

  use BikeBrigade.SingleGlobalGenServer, initial_state: %{}

  # Run every 15 minutes
  @check_interval :timer.minutes(15)

  @impl GenServer
  def init(state) do
    :timer.send_interval(@check_interval, :post_summaries)
    {:ok, state}
  end

  @impl GenServer
  def handle_info(:post_summaries, state) do
    Logger.info("Campaign summary scheduler running...")

    campaigns = find_campaigns_to_summarize()

    Enum.each(campaigns, fn campaign ->
      post_campaign_summary(campaign)
    end)

    {:noreply, state}
  end

  @doc """
  Finds campaigns that ended 60-75 minutes ago for summary posting.

  The 60-minute minimum provides a buffer for riders to complete deliveries and ensures
  stable data. The 15-minute window (60-75 min) aligns with the scheduler interval to catch
  each campaign exactly once. Deduplication happens via atomic transaction in `post_campaign_summary/1`.
  """
  def find_campaigns_to_summarize do
    now = DateTime.utc_now()
    window_start = DateTime.add(now, -75, :minute)
    window_end = DateTime.add(now, -60, :minute)

    Delivery.list_campaigns(
      delivery_end_from: window_start,
      delivery_end_to: window_end
    )
  end

  def post_campaign_summary(campaign) do
    case claim_campaign_for_summary(campaign.id) do
      {:ok, _summary} ->
        Logger.info("Claimed campaign #{campaign.id} for summary posting")

        case Messaging.Slack.CampaignSummary.send_campaign_summary(campaign) do
          :ok ->
            Logger.info("Successfully posted campaign summary for campaign #{campaign.id}")
            :ok

          error ->
            Logger.error(
              "Failed to post campaign summary for campaign #{campaign.id}: #{inspect(error)}"
            )

            # Note: Record already claimed, won't retry automatically
            {:error, error}
        end

      {:error, :already_claimed} ->
        Logger.debug("Campaign #{campaign.id} already has summary, skipping")
        :skip
    end
  end

  defp claim_campaign_for_summary(campaign_id) do
    Repo.transaction(fn ->
      case Repo.get_by(Messaging.CampaignSummary, campaign_id: campaign_id) do
        nil ->
          %Messaging.CampaignSummary{}
          |> Messaging.CampaignSummary.changeset(%{
            campaign_id: campaign_id,
            send_at: DateTime.utc_now()
          })
          |> Repo.insert!()

        _existing ->
          Repo.rollback(:already_claimed)
      end
    end)
  end
end
