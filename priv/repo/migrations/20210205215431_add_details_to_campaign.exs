defmodule BikeBrigade.Repo.Migrations.AddDetailsToCampaign do
  use Ecto.Migration

  def change do
    alter table(:campaigns) do
      add :details, :text
    end
  end
end
