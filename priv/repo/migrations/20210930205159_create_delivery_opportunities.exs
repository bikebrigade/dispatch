defmodule BikeBrigade.Repo.Migrations.CreateDeliveryOpportunities do
  use Ecto.Migration

  def change do
    create table(:delivery_opportunities) do
      add :delivery_start, :utc_datetime_usec
      add :delivery_end, :utc_datetime_usec
      add :signup_link, :string
      add :published, :boolean, default: false, null: false
      add :program_id, references(:programs, on_delete: :nothing)
      add :campaign_id, references(:campaigns, on_delete: :nothing)

      timestamps()
    end

    create index(:delivery_opportunities, [:program_id])
    create index(:delivery_opportunities, [:campaign_id])
  end
end
