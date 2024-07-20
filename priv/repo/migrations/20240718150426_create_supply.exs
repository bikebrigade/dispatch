defmodule BikeBrigade.Repo.Migrations.CreateSupply do
  use Ecto.Migration

  def change do
    # rename tasks items table to supply & add columns

    rename table(:tasks_items), to: :supplies

    rename column(:supplies, :count, :quantity)

    alter table(:supplies) do
      add :campaign_id, references(:campaigns, on_delete: :delete_all)

    end


    # Backfill
    # for each existing task
    #

  end
end
