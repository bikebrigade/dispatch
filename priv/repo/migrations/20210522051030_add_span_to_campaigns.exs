defmodule BikeBrigade.Repo.Migrations.AddSpanToCampaigns do
  use Ecto.Migration

  def change do
    alter table(:campaigns) do
      add :delivery_start, :utc_datetime
      add :delivery_end, :utc_datetime
    end
  end
end
