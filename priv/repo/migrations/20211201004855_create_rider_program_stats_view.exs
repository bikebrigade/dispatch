defmodule BikeBrigade.Repo.Migrations.CreateRiderProgramStatsView do
  use Ecto.Migration

  def up do
    execute view("rider_program_stats.sql")
  end

  def down do
    execute "drop view rider_program_stats;"
  end

  defp view(view_filename) do
    Path.join([
      :code.priv_dir(:bike_brigade),
      "repo",
      "views",
      view_filename
    ])
    |> File.read!()
  end
end
