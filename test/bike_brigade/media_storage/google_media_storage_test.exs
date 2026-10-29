defmodule BikeBrigade.MediaStorage.GoogleMediaStorageTest do
  use ExUnit.Case, async: true

  alias BikeBrigade.MediaStorage.GoogleMediaStorage

  @tag :tmp_dir
  test "uploads the file to the bucket and returns its media link", %{tmp_dir: tmp_dir} do
    path = Path.join(tmp_dir, "photo.png")
    File.write!(path, "png bytes")

    Req.Test.stub(BikeBrigade.Google, fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      send(self(), {:upload, conn, body})
      Req.Test.json(conn, %{"mediaLink" => "https://storage.googleapis.com/media/photo.png"})
    end)

    assert {:ok,
            %{url: "https://storage.googleapis.com/media/photo.png", content_type: "image/png"}} =
             GoogleMediaStorage.upload_file(path, "image/png", "my-bucket")

    assert_received {:upload, conn, body}
    assert conn.request_path == "/upload/storage/v1/b/my-bucket/o"
    assert conn.query_params == %{"uploadType" => "multipart"}
    assert body =~ Jason.encode!(%{name: "photo.png", contentType: "image/png"})
    assert body =~ "Content-Type: image/png\r\n\r\npng bytes\r\n"
  end
end
