defmodule BikeBrigade.Repo.Migrations.AddRiderSheetToCampaign do
  use Ecto.Migration

  def change do
    alter table(:campaigns) do
      remove :rider_spreadsheet_id
      add :rider_spreadsheet_id, :string
    end
  end
end
