defmodule BikeBrigade.Repo.Migrations.JoinTableDeletes do
  use Ecto.Migration

  def change do
    alter table(:campaigns_riders) do
      modify :campaign_id, references(:campaigns, on_delete: :delete_all),
        from: references(:campaigns)

      modify :rider_id, references(:riders, on_delete: :delete_all), from: references(:riders)
    end
  end
end
