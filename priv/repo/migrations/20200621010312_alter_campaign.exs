defmodule BikeBrigade.Repo.Migrations.AlterCampaign do
  use Ecto.Migration

  def change do
    rename(table(:campaigns_tasks), :task_collection_id, to: :campaign_id)
  end
end
