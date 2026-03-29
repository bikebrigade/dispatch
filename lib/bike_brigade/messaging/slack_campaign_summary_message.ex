defmodule BikeBrigade.Messaging.SlackCampaignSummaryMessage do
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

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @available_params)
    |> validate_required(@required_params)
  end
end
