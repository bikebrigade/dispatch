defmodule BikeBrigade.MigrationUtils do
  @doc """
  Creates a view with a given `name`, with the sql for it in `repo/sql/<filename>`
  """
  # Be careful about changing this as migrations depend on it.
  require Logger

  def load_sql(filename, reverse \\ nil) do
    path =
      Path.join([
        :code.priv_dir(:bike_brigade),
        "repo",
        "sql",
        filename
      ])

    case File.read(path) do
      {:ok, sql} ->
        if reverse do
          Ecto.Migration.execute(sql, reverse)
        else
          Ecto.Migration.execute(sql)
        end

      {:error, err} ->
        Logger.warn(
          "Ignoring file referenced in migration #{filename} - due to error #{:file.format_error(err)}"
        )
    end
  end
end
