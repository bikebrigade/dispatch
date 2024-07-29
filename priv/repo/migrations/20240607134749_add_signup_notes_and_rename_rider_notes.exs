defmodule BikeBrigade.Repo.Migrations.AddSignupNotesAndRenameRiderNotes do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      add :signup_notes, :text
    end

    rename table(:tasks), :rider_notes, to: :delivery_instructions
  end
end
