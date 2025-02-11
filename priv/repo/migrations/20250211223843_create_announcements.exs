defmodule BikeBrigade.Repo.Migrations.CreateAnnouncements do
  use Ecto.Migration

  def change do
    create table(:announcements) do
      add :message, :text
      add :turn_on_at, :utc_datetime_usec
      add :turn_off_at, :utc_datetime_usec
      add :created_by, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:announcements, [:created_by])
  end
end
