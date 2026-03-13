defmodule BikeBrigade.Messaging.CampaignSummary do
  @moduledoc """
  Tracks which campaigns have had their end-of-campaign summaries posted to Slack.
  """

  use BikeBrigade.Schema

  alias BikeBrigade.Delivery.Campaign

  import Ecto.Changeset

  schema "campaign_summaries" do
    field :send_at, :utc_datetime
    belongs_to :campaign, Campaign

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:send_at, :campaign_id])
    |> validate_required([:campaign_id])
    |> unique_constraint(:campaign_id)
  end
end
