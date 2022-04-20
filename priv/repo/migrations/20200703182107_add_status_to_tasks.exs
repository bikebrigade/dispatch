defmodule BikeBrigade.Repo.Migrations.AddStatusToTasks do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      add :delivery_status, :string
    end

    rename table(:tasks), :logistics_notes, to: :delivery_status_notes
  end
end
