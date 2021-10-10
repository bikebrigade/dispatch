defmodule BikeBrigade.Repo.Migrations.DropCampaignTask do
  use Ecto.Migration

  def change do
    drop table(:campaigns_tasks)
  end
end
