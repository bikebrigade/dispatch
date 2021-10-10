defmodule BikeBrigade.Repo.Migrations.AddPartnerToTasks do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      add(:organization_partner, :string)
    end
  end
end
