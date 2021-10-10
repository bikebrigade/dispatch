defmodule BikeBrigade.Repo.Migrations.AddProgramToItems do
  use Ecto.Migration

  def change do
    alter table(:items) do
      add :program_id, references(:programs)
      remove :identifier
    end
  end
end
