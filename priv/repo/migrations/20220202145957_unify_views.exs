defmodule BikeBrigade.Repo.Migrations.UnifyViews do
  use Ecto.Migration

  import BikeBrigade.Repo.Helpers

  def up do
    execute "drop view if exists rider_program_stats"
    execute "drop view if exists rider_stats"
    load_sql("rider_stats_view.sql")
  end

  def down do

  end
end
