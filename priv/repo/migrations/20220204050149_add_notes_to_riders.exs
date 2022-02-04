defmodule BikeBrigade.Repo.Migrations.AddNotesToRiders do
  use Ecto.Migration

  def change do
    alter table(:riders) do
      add :internal_notes, :text
    end
  end
end
