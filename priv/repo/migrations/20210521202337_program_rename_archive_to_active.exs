defmodule BikeBrigade.Repo.Migrations.ProgramRenameArchiveToActive do
  use Ecto.Migration

  def change do
    alter table(:programs) do
      remove :archived
      add :active, :boolean, default: true
    end
  end
end
