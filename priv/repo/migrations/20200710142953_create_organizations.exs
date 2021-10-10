defmodule BikeBrigade.Repo.Migrations.CreateOrganizations do
  use Ecto.Migration

  def change do
    create table(:organizations) do
      add :name, :string
      add :contact_name, :string
      add :contact_email, :string
      add :contact_phone, :string
      add :description, :text
      add :account_manager_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    alter table(:campaigns) do
      add :organization_id, references(:organizations, on_delete: :nothing)
    end

    create(index(:campaigns, [:organization_id]))
    create(index(:organizations, [:account_manager_id]))
  end
end
