defmodule BikeBrigade.Repo.Migrations.AddSpreadsheetLayoutToOrganizations do
  use Ecto.Migration

  def change do
    alter table(:organizations) do
      add :spreadsheet_layout, :string
    end
  end
end
