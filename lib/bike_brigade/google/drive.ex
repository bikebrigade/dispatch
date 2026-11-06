defmodule BikeBrigade.Google.Drive do
  alias BikeBrigade.Google
  alias BikeBrigade.Google.MultipartUpload

  @upload_url "https://www.googleapis.com/upload/drive/v3/files"

  def upload_file(path, parent, opts \\ []) do
    with {:ok, content} <- File.read(path) do
      upload_content(content, parent, opts)
    end
  end

  defp upload_content(content, parent, opts) do
    MultipartUpload.upload(
      @upload_url,
      %{
        name: Keyword.get(opts, :name),
        parents: [parent],
        mimeType: Keyword.get(opts, :content_type)
      },
      content,
      Keyword.get(opts, :content_type),
      supportsAllDrives: true,
      fields: "id, name, webViewLink"
    )
  end

  def upload_from_url(url, parent, opts \\ []) do
    # The media URL isn't a Google API, so it gets no Google auth
    with {:ok, %Req.Response{status: 200, body: body}} <-
           Req.get(url, [decode_body: false] ++ Google.req_options()),
         {:ok, file} <-
           upload_content(body, parent, opts) do
      {:ok, file}
    else
      {:ok, %Req.Response{status: status}} -> {:error, {:download_failed, status}}
      {:error, reason} -> {:error, reason}
    end
  end
end
