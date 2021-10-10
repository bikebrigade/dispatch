defmodule BikeBrigade.Repo.Migrations.AddCampaignToTask do
  use Ecto.Migration
  alias BikeBrigade.Repo
  alias BikeBrigade.Delivery.{Task,CampaignTask}
  alias BikeBrigade.Messaging.SmsMessage
  import Ecto.Query
  def up do
    alter table(:tasks) do
      add :campaign_id, references(:campaigns, on_delete: :delete_all)
    end

    flush()

    from(t in "tasks",
      join: ct in "campaigns_tasks",
      on: ct.task_id == t.id,
      update: [set: [campaign_id: ct.campaign_id]])
    |> Repo.update_all([])

  end

  def down do
    alter table(:tasks) do
      remove :campaign_id
    end
  end
end
