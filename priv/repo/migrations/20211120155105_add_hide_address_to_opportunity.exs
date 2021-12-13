defmodule BikeBrigade.Repo.Migrations.AddHideAddressToOpportunity do
  use Ecto.Migration

  def change do
    alter table(:delivery_opportunities) do
      add :hide_address, :boolean, default: false
    end
  end
end
