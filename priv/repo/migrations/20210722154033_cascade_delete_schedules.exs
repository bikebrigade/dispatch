defmodule BikeBrigade.Repo.Migrations.CascadeDeleteSchedules do
  use Ecto.Migration

  def change do
    alter table(:scheduled_messages) do
      modify :campaign_id, references(:campaigns, on_delete: :delete_all), from: references(:campaigns)
    end
  end
end
