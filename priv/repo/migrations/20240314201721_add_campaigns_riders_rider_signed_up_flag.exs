defmodule BikeBrigade.Repo.Migrations.AddCampaignsRidersRiderSignedUpFlag do
  use Ecto.Migration
  def change do
    alter table(:campaigns_riders) do
      add :rider_signed_up, :boolean, default: false
    end
  end
end
