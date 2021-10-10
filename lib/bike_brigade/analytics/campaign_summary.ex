defmodule BikeBrigade.Analytics.CampaignSummary do
  use BikeBrigade.Schema
  import Ecto.Changeset

  schema "analytics_campaign_summaries" do
    field :delivery_window, :string
    field :distance_covered, :integer
    field :failed_count, :integer
    field :riders_count, :integer
    field :tasks_count, :integer
    field :campaign_id, :id

    timestamps()
  end

  @doc false
  def changeset(campaign_summary, attrs) do
    campaign_summary
    |> cast(attrs, [:delivery_window, :tasks_count, :riders_count, :distance_covered, :failed_count])
    |> validate_required([:delivery_window, :tasks_count, :riders_count, :distance_covered, :failed_count])
  end
end
