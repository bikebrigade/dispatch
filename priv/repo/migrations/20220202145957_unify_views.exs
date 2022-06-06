defmodule BikeBrigade.Repo.Migrations.UnifyViews do
  use Ecto.Migration

  # import BikeBrigade.MigrationUtils

  def up do
    # removing since we load these views later

    #   execute "drop view if exists rider_program_stats"
    #   execute "drop view if exists rider_stats"
    #   load_sql("rider_stats_view.sql")
  end

  def down do
  end
end
