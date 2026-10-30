defmodule BikeBrigade.Google.MultipartUploadTest do
  use ExUnit.Case, async: true

  alias BikeBrigade.Google.MultipartUpload

  @url "https://www.googleapis.com/upload/drive/v3/files"

  test "sends metadata and content as multipart/related with auth and query params" do
    Req.Test.stub(BikeBrigade.Google, fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      send(self(), {:request, conn, body})
      Req.Test.json(conn, %{"id" => "file-id"})
    end)

    assert {:ok, %{"id" => "file-id"}} =
             MultipartUpload.upload(@url, %{name: "photo.jpg"}, "jpeg bytes", "image/jpeg",
               fields: "id"
             )

    assert_received {:request, conn, body}

    assert conn.method == "POST"
    assert conn.host == "www.googleapis.com"
    assert conn.request_path == "/upload/drive/v3/files"
    assert conn.query_params == %{"uploadType" => "multipart", "fields" => "id"}
    assert Plug.Conn.get_req_header(conn, "authorization") == ["Bearer test-token"]

    assert ["multipart/related; boundary=" <> boundary] =
             Plug.Conn.get_req_header(conn, "content-type")

    assert [metadata_part, content_part] = parts(body, boundary)

    assert metadata_part ==
             {"application/json; charset=UTF-8", Jason.encode!(%{name: "photo.jpg"})}

    assert content_part == {"image/jpeg", "jpeg bytes"}
  end

  test "returns the status and body on an HTTP error" do
    Req.Test.stub(BikeBrigade.Google, fn conn ->
      conn
      |> Plug.Conn.put_status(403)
      |> Req.Test.json(%{"error" => %{"message" => "forbidden"}})
    end)

    assert {:error, {:http_error, 403, %{"error" => %{"message" => "forbidden"}}}} =
             MultipartUpload.upload(@url, %{}, "x", "text/plain")
  end

  test "returns transport errors" do
    Req.Test.stub(BikeBrigade.Google, &Req.Test.transport_error(&1, :timeout))

    assert {:error, %Req.TransportError{reason: :timeout}} =
             MultipartUpload.upload(@url, %{}, "x", "text/plain")
  end

  # Splits a multipart body into {content_type, content} tuples
  defp parts(body, boundary) do
    [_preamble | parts] = String.split(body, "--#{boundary}")
    {parts, ["--\r\n"]} = Enum.split(parts, -1)

    for part <- parts do
      ["\r\nContent-Type: " <> content_type, content] =
        part |> String.trim_trailing("\r\n") |> String.split("\r\n\r\n", parts: 2)

      {content_type, content}
    end
  end
end
