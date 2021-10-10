defmodule BikeBrigade.Repo.Migrations.AddNotesToCampaignRiders do
  use Ecto.Migration

  def change do
    alter table(:campaigns_riders) do
      add :notes, :text
      add :pickup_window, :string
    end
  end
end
