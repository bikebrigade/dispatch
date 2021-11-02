defmodule BikeBrigade.MediaStorage.GoogleMediaStorage do
  alias GoogleApi.Storage.V1.Connection
  alias GoogleApi.Storage.V1.Api.Objects

  @behaviour BikeBrigade.MediaStorage

  def upload_file(path, content_type, bucket) do
    with {:ok, token} <- get_token(),
         conn <- connect(token),
         {:ok, obj} <- upload(conn, bucket, path, content_type) do
      {:ok, %{url: obj.mediaLink, content_type: content_type}}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp get_token() do
    Goth.fetch(BikeBrigade.Google)
  end

  defp connect(token) do
    Connection.new(token.token)
  end

  defp upload(conn, bucket, path, content_type) do
    Objects.storage_objects_insert_simple(
      conn,
      bucket,
      "multipart",
      %{name: Path.basename(path), contentType: content_type},
      path
    )
  end
end
