defmodule BikeBrigade.Repo.Migrations.AddFieldsToProgram do
  use Ecto.Migration

  def change do
    alter table(:programs) do
      add :archived, :boolean, default: :false
      add :rrule, :string
    end
  end
end
