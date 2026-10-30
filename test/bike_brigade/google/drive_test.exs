defmodule BikeBrigade.Google.DriveTest do
  use ExUnit.Case, async: true

  alias BikeBrigade.Google.Drive

  @media_url "https://api.twilio.com/media/123"

  test "downloads the media and uploads it to the parent folder" do
    Req.Test.stub(BikeBrigade.Google, fn
      %{host: "api.twilio.com"} = conn ->
        send(self(), {:download, conn})

        conn
        |> Plug.Conn.put_resp_content_type("image/jpeg")
        |> Plug.Conn.send_resp(200, "jpeg bytes")

      %{host: "www.googleapis.com"} = conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        send(self(), {:upload, conn, body})

        Req.Test.json(conn, %{
          "id" => "file-id",
          "name" => "photo",
          "webViewLink" => "https://drive.google.com/file/d/file-id/view"
        })
    end)

    assert {:ok, %{"webViewLink" => "https://drive.google.com/file/d/file-id/view"}} =
             Drive.upload_from_url(@media_url, "folder-id",
               name: "photo",
               content_type: "image/jpeg"
             )

    assert_received {:download, download}
    # Google credentials must not leak to the media host
    assert Plug.Conn.get_req_header(download, "authorization") == []

    assert_received {:upload, upload, body}
    assert upload.request_path == "/upload/drive/v3/files"

    assert upload.query_params == %{
             "uploadType" => "multipart",
             "supportsAllDrives" => "true",
             "fields" => "id, name, webViewLink"
           }

    assert body =~
             Jason.encode!(%{name: "photo", parents: ["folder-id"], mimeType: "image/jpeg"})

    assert body =~ "Content-Type: image/jpeg\r\n\r\njpeg bytes\r\n"
  end

  test "returns an error without uploading when the download fails" do
    Req.Test.stub(BikeBrigade.Google, fn
      %{host: "api.twilio.com"} = conn -> Plug.Conn.send_resp(conn, 404, "not found")
      %{host: "www.googleapis.com"} -> flunk("should not upload")
    end)

    assert {:error, {:download_failed, 404}} =
             Drive.upload_from_url(@media_url, "folder-id",
               name: "photo",
               content_type: "image/jpeg"
             )
  end
end
