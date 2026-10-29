defmodule BikeBrigade.Google.Drive do
  alias BikeBrigade.Google.MultipartUpload

  @upload_url "https://www.googleapis.com/upload/drive/v3/files"

  def upload_from_url(url, parent, opts \\ []) do
    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           HTTPoison.get(url, [], follow_redirect: true),
         {:ok, file} <-
           MultipartUpload.upload(
             @upload_url,
             %{
               name: Keyword.get(opts, :name),
               parents: [parent],
               mimeType: Keyword.get(opts, :content_type)
             },
             body,
             Keyword.get(opts, :content_type),
             supportsAllDrives: true,
             fields: "id, name, webViewLink"
           ) do
      {:ok, file}
    else
      {:ok, %HTTPoison.Response{status_code: status}} -> {:error, {:download_failed, status}}
      {:error, reason} -> {:error, reason}
    end
  end
end
