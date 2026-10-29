defmodule BikeBrigade.MediaStorage.GoogleMediaStorage do
  alias BikeBrigade.Google.MultipartUpload

  @behaviour BikeBrigade.MediaStorage

  def upload_file(path, content_type, bucket) do
    with {:ok, content} <- File.read(path),
         {:ok, obj} <-
           MultipartUpload.upload(
             "https://storage.googleapis.com/upload/storage/v1/b/#{URI.encode(bucket)}/o",
             %{name: Path.basename(path), contentType: content_type},
             content,
             content_type
           ) do
      {:ok, %{url: obj["mediaLink"], content_type: content_type}}
    else
      {:error, reason} -> {:error, reason}
    end
  end
end
