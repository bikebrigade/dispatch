defmodule BikeBrigade.Repo.Migrations.IncreaseSizeOfNotesField do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      modify :rider_notes, :text
    end
  end
end
