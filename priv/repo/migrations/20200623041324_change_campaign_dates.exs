defmodule BikeBrigade.Repo.Migrations.ChangeCampaignDates do
  use Ecto.Migration

  def change do
    alter table(:campaigns) do
      remove :delivery_start
      remove :delivery_end
      add :delivery_date, :date
    end
  end
end
