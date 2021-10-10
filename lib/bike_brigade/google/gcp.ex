defmodule BikeBrigade.Google.GCP do
  def upload_object(bucket, path, opts \\ []) do
    with {:ok, token} <- Goth.fetch(BikeBrigade.Google),
         conn <- GoogleApi.Storage.V1.Connection.new(token.token) do
      GoogleApi.Storage.V1.Api.Objects.storage_objects_insert_simple(
        conn,
        bucket,
        "multipart",
        %{name: Path.basename(path), contentType: Keyword.get(opts, :content_type)},
        path
      )
    else
      err -> err
    end
  end
end
