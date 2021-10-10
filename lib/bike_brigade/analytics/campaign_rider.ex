defmodule BikeBrigade.Analytics.CampaignRider do
  use BikeBrigade.Schema
  import Ecto.Changeset

  schema "analytics_campaign_riders" do
    field :capacity, :integer
    field :pickup_window, :string
    field :campaign_id, :id
    field :rider_id, :id

    timestamps()
  end

  @doc false
  def changeset(campaign_rider, attrs) do
    campaign_rider
    |> cast(attrs, [:capacity, :pickup_window])
    |> validate_required([:capacity, :pickup_window])
  end
end
