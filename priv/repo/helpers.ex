defmodule BikeBrigade.Repo.Helpers  do
  @doc """
  Creates a view with a given `name`, with the sql for it in `repo/sql/<filename>`
  """
  # Be careful about changing this as migrations depend on it.
  def create_or_replace_view(name, filename) do
    Path.join([
      :code.priv_dir(:bike_brigade),
      "repo",
      "sql",
      filename
    ])
    |> File.read!()
    |> Ecto.Migration.execute("drop view if exists #{name}")
  end
end
