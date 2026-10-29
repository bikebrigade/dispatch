defmodule BikeBrigade.Google.MultipartUpload do
  @moduledoc """
  Google API multipart (metadata + media) uploads.

  We build the `multipart/related` request ourselves because `google_gax`
  passes atom field names to `Tesla.Multipart`, which Tesla >= 1.19 rejects.
  """

  @boundary "bike_brigade_upload_boundary"

  def upload(url, metadata, content, content_type, query \\ []) do
    with {:ok, token} <- Goth.fetch(BikeBrigade.Google),
         {:ok, %HTTPoison.Response{status_code: status, body: body}} when status in 200..299 <-
           HTTPoison.post(
             url,
             build_body(metadata, content, content_type),
             [
               {"Authorization", "Bearer #{token.token}"},
               {"Content-Type", "multipart/related; boundary=#{@boundary}"}
             ],
             params: [{:uploadType, "multipart"} | query]
           ) do
      Jason.decode(body)
    else
      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp build_body(metadata, content, content_type) do
    [
      "--#{@boundary}\r\n",
      "Content-Type: application/json; charset=UTF-8\r\n\r\n",
      Jason.encode!(metadata),
      "\r\n--#{@boundary}\r\n",
      "Content-Type: #{content_type}\r\n\r\n",
      content,
      "\r\n--#{@boundary}--\r\n"
    ]
  end
end
