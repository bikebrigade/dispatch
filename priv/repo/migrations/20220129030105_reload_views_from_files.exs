defmodule BikeBrigade.Repo.Migrations.ReloadViewsFromFiles do
  use Ecto.Migration

  def change do
    execute "drop view if exists rider_stats", ""
    flush()
    execute load_sql("rider_stats_view.sql"), "drop view rider_stats"
    execute load_sql("rider_program_stats_view.sql"), "drop view rider_program_stats"
    execute load_sql("riders_latest_campaigns_view.sql"), "drop view riders_latest_campaigns"

  end

  defp load_sql(filename) do
    Path.join([
      :code.priv_dir(:bike_brigade),
      "repo",
      "sql",
      filename
    ])
    |> File.read!()
  end
end
