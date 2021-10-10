defmodule BikeBrigade.Repo.Migrations.RenameDriverNotesToRiderNotes do
  use Ecto.Migration

  def change do
    rename table(:tasks), :driver_notes, to: :rider_notes
    rename table(:tasks), :pickup_province_string, to: :pickup_province
    rename table(:tasks), :pickup_loacation, to: :pickup_location

  end
end
