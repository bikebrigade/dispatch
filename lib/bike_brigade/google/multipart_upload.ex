defmodule BikeBrigade.Google.MultipartUpload do
  @moduledoc """
  Google API multipart (metadata + media) uploads.

  Google documents these uploads as `multipart/related`, which `Req` doesn't
  encode (its `:form_multipart` is `multipart/form-data`), so we build the body.
  """

  @boundary "bike_brigade_upload_boundary"

  def upload(url, metadata, content, content_type, query \\ []) do
    with {:ok, req} <- BikeBrigade.Google.request(),
         {:ok, %Req.Response{status: status, body: body}} when status in 200..299 <-
           Req.post(req,
             url: url,
             params: [{:uploadType, "multipart"} | query],
             headers: [content_type: "multipart/related; boundary=#{@boundary}"],
             body: build_body(metadata, content, content_type)
           ) do
      {:ok, body}
    else
      {:ok, %Req.Response{status: status, body: body}} ->
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
