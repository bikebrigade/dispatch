defmodule BikeBrigade.MediaStorageTest do
  use BikeBrigade.DataCase, async: true

  alias BikeBrigade.MediaStorage
  alias BikeBrigade.MediaStorage.FakeMediaStorage

  test "media is sent to the configured bucket with the path and content type" do
    MediaStorage.upload_file!("file.txt", "text/plain")
    {request, response} = FakeMediaStorage.last_upload()

    assert request.path == "file.txt"
    assert request.content_type == "text/plain"
    assert request.bucket == "bike-brigade-public"

    assert match?({:ok, %{url: _, content_type: "text/plain"}}, response)
  end
end
