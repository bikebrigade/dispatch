defmodule BikeBrigade.Messaging.GoogleDriveUploadTest do
  use BikeBrigade.DataCase, async: true

  import ExUnit.CaptureLog

  alias BikeBrigade.Messaging.GoogleDriveUpload

  @folder_url "https://drive.google.com/drive/folders/12avCsCaaNEtxcqvdUiijSQhWGyRBjC0B"

  setup do
    %{rider: fixture(:rider)}
  end

  test "uploads media and saves the Drive links", %{rider: rider} do
    message = message_with_media(rider, [%{url: "https://media.example.com/ok/1"}])
    stub_media()

    assert {:ok, message} = GoogleDriveUpload.upload_media(message)

    assert [%{gdrive_url: "https://drive.google.com/file/d/1", gdrive_folder_url: @folder_url}] =
             message.media

    assert_received {:upload, "1"}
  end

  test "skips media that is already uploaded", %{rider: rider} do
    message =
      message_with_media(rider, [
        %{url: "https://media.example.com/ok/1", gdrive_url: "https://drive.google.com/existing"},
        %{url: "https://media.example.com/ok/2"}
      ])

    stub_media()

    assert {:ok, message} = GoogleDriveUpload.upload_media(message)

    assert [
             %{gdrive_url: "https://drive.google.com/existing"},
             %{gdrive_url: "https://drive.google.com/file/d/2"}
           ] =
             message.media

    refute_received {:download, "1"}
    refute_received {:upload, "1"}
    assert_received {:upload, "2"}
  end

  test "skips media with a disallowed content type", %{rider: rider} do
    message =
      message_with_media(rider, [
        %{url: "https://media.example.com/ok/1", content_type: "image/gif"}
      ])

    stub_media()

    assert {:ok, message} = GoogleDriveUpload.upload_media(message)
    assert [%{gdrive_url: nil}] = message.media
    refute_received {:download, _}
  end

  test "a failed upload is logged and the other media still uploads", %{rider: rider} do
    message =
      message_with_media(rider, [
        %{url: "https://media.example.com/missing/1"},
        %{url: "https://media.example.com/ok/2"}
      ])

    stub_media()

    log =
      capture_log(fn ->
        assert {:ok, message} = GoogleDriveUpload.upload_media(message)

        assert [%{gdrive_url: nil}, %{gdrive_url: "https://drive.google.com/file/d/2"}] =
                 message.media
      end)

    assert log =~ "Failed to upload media"
    assert log =~ "{:download_failed, 404}"
    assert_received {:upload, "2"}
  end

  defp message_with_media(rider, media) do
    fixture(:sms_message, %{
      rider_id: rider.id,
      media: Enum.map(media, &fixture(:sms_media_item, &1))
    })
  end

  # Media at /ok/<n> downloads as "media <n>" and uploads as Drive file <n>;
  # media at /missing/<n> 404s.
  defp stub_media do
    Req.Test.stub(BikeBrigade.Google, fn
      %{host: "media.example.com", path_info: ["ok", n]} = conn ->
        send(self(), {:download, n})
        Plug.Conn.send_resp(conn, 200, "media #{n}")

      %{host: "media.example.com"} = conn ->
        Plug.Conn.send_resp(conn, 404, "not found")

      %{host: "www.googleapis.com"} = conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        [_, n] = Regex.run(~r/media (\d+)/, body)
        send(self(), {:upload, n})

        Req.Test.json(conn, %{"id" => n, "webViewLink" => "https://drive.google.com/file/d/#{n}"})
    end)
  end
end
