defmodule BikeBrigade.Repo.Migrations.AddAnonymizedRiderFlag do
  use Ecto.Migration

  def change do
    alter table(:riders) do
      add :anonymous_in_leaderboard, :boolean, default: true
    end
  end
end
