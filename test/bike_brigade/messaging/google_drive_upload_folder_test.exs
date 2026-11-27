defmodule BikeBrigade.Messaging.GoogleDriveUploadFolderTest do
  # Not async: changes the global Drive folder setting
  use BikeBrigade.DataCase

  alias BikeBrigade.Messaging.GoogleDriveUpload

  setup do
    folder = Application.fetch_env!(:bike_brigade, :drive_media_folder_id)
    Application.put_env(:bike_brigade, :drive_media_folder_id, "STAGING_FOLDER")
    on_exit(fn -> Application.put_env(:bike_brigade, :drive_media_folder_id, folder) end)
  end

  test "uploads media to the configured folder" do
    rider = fixture(:rider)

    message =
      fixture(:sms_message, %{
        rider_id: rider.id,
        media: [fixture(:sms_media_item, %{url: "https://media.example.com/ok/1"})]
      })

    test_pid = self()

    Req.Test.stub(BikeBrigade.Google, fn
      %{host: "media.example.com"} = conn ->
        Plug.Conn.send_resp(conn, 200, "media 1")

      conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        send(test_pid, {:upload, body})
        Req.Test.json(conn, %{"id" => "1", "webViewLink" => "https://drive.google.com/file/d/1"})
    end)

    assert {:ok, message} = GoogleDriveUpload.upload_media(message)
    assert_received {:upload, body}
    assert body =~ ~s("parents":["STAGING_FOLDER"])

    assert [%{gdrive_folder_url: "https://drive.google.com/drive/folders/STAGING_FOLDER"}] =
             message.media
  end
end
