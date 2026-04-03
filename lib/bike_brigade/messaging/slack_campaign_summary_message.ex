defmodule BikeBrigade.Messaging.SlackCampaignSummaryMessage do
  @moduledoc """
  Schema for tracking campaign delivery summary messages sent to Slack.

  Used to prevent duplicate postings by storing a record for each campaign
  summary. The `sent_at` field indicates whether the message was successfully
  delivered to Slack.

  ## Fields

    * `:slack_channel_id` - The Slack channel where the message was sent
    * `:raw_message` - The raw message content (inspected summary struct)
    * `:sent_at` - Timestamp when the message was successfully sent to Slack
    * `:campaign_id` - Reference to the associated campaign
  """

  use BikeBrigade.Schema

  alias BikeBrigade.Delivery.Campaign

  import Ecto.Changeset

  schema "slack_campaign_messages" do
    field :slack_channel_id, :string
    field :raw_message, :string
    field :sent_at, :utc_datetime
    belongs_to :campaign, Campaign

    timestamps()
  end

  @required_params [:slack_channel_id, :raw_message, :campaign_id]
  @available_params [:sent_at | @required_params]

  @doc "Builds a changeset for creating or updating a Slack campaign summary message."
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @available_params)
    |> validate_required(@required_params)
  end
end
