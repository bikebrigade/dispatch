defmodule BikeBrigade.Analytics.CampaignTask do
  use BikeBrigade.Schema
  import Ecto.Changeset

  schema "analytics_campaign_tasks" do
    field :campaign_id, :id
    field :task_id, :id

    timestamps()
  end

  @doc false
  def changeset(campaign_task, attrs) do
    campaign_task
    |> cast(attrs, [])
    |> validate_required([])
  end
end
