defmodule BikeBrigade.Repo.Migrations.CreateSpreadsheets do
  use Ecto.Migration

  def change do
    create table(:spreadsheets) do
      add :spreadsheet_id, :string
      add :stop_updating_at, :utc_datetime
      add :last_row, :integer
      add :mfa, :map

      timestamps()
    end
  end
end
