defmodule BikeBrigade.Repo.Migrations.DropSpreadsheets do
  use Ecto.Migration

  def up do
    drop table(:spreadsheets)
  end

  def down do
    create table(:spreadsheets) do
      add :spreadsheet_id, :string
      add :stop_updating_at, :utc_datetime
      add :last_row, :integer
      add :mfa, :map

      timestamps()
    end
  end
end
