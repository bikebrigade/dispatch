defmodule BikeBrigade.Repo.Migrations.RenameOrganizationToProgram do
  use Ecto.Migration

  def change do
    drop index(:organizations, [:account_manager_id])
    drop index(:campaigns, [:organization_id])

    rename table(:organizations), to: table(:programs)
    rename table(:programs), :account_manager_id, to: :lead_id
    rename table(:campaigns), :organization_id, to: :program_id

    create index(:programs, [:lead_id])
    create index(:campaigns, [:program_id])
  end
end
