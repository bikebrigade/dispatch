defmodule BikeBrigade.Repo.Migrations.AddRiderSpreadsheetLayoutToCampaigns do
  use Ecto.Migration

  def change do
    alter table(:campaigns) do
      add :rider_spreadsheet_layout, :integer, default: 0
    end
  end
end
