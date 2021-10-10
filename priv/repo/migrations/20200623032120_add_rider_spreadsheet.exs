defmodule BikeBrigade.Repo.Migrations.AddRiderSpreadsheet do
  use Ecto.Migration

  def change do
    alter table(:campaigns) do
      add :rider_spreadsheet_id, references(:spreadsheets)
    end
  end
end
