defmodule BikeBrigade.Repo.Helpers do
  @doc """
  Creates a view with a given `name`, with the sql for it in `repo/sql/<filename>`
  """
  # Be careful about changing this as migrations depend on it.
  require Logger

  def load_sql(filename) do
    path =
      Path.join([
        :code.priv_dir(:bike_brigade),
        "repo",
        "sql",
        filename
      ])

    case File.read(path) do
      {:ok, sql} ->
        Ecto.Migration.execute(sql)

      {:error, err} ->
        Logger.warn(
          "Ignoring file referenced in migration #{filename} - due to error #{:file.format_error(err)}"
        )
    end
  end
end
