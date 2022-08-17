defmodule BikeBrigade.MigrationUtils do
  @doc """
  Creates a view with a given `name`, with the sql for it in `repo/sql/<filename>`
  """
  require Logger

  # Be careful about changing this as migrations depend on it.
  def load_sql(filename, down \\ nil, order \\ :normal) do
    path =
      Path.join([
        :code.priv_dir(:bike_brigade),
        "repo",
        "sql",
        filename
      ])

    case File.read(path) do
      {:ok, sql} ->
        cond do
          is_nil(down) -> Ecto.Migration.execute(sql)
          order == :normal -> Ecto.Migration.execute(sql, down)
          order == :reverse -> Ecto.Migration.execute(down, sql)
        end

      {:error, err} ->
        Logger.warn(
          "Ignoring file referenced in migration #{filename} - due to error #{:file.format_error(err)}"
        )
    end
  end

  def load_view(name) do
    filename = "#{name}_view.sql"

    load_sql(filename, "DROP VIEW IF EXISTS #{name}")
  end

  def drop_view(name) do
    filename = "#{name}_view.sql"
    load_sql(filename, "DROP VIEW IF EXISTS #{name}", :reverse)
  end
end
