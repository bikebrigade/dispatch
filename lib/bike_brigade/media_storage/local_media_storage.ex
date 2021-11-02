defmodule BikeBrigade.MediaStorage.LocalMediaStorage do
  require Logger

  alias BikeBrigade.MediaStorage
  alias BikeBrigadeWeb.Endpoint

  @behaviour MediaStorage

  @impl MediaStorage
  def upload_file(path, content_type, bucket) do
    relative_path =
      Path.join(
        [
          "static",
          "images",
          "media_bucket",
          bucket
        ] ++ String.split(path, "/")
      )

    local_path =
      :code.priv_dir(:bike_brigade)
      |> Path.join(relative_path)
      |> Path.expand()

    local_path
    |> Path.dirname()
    |> File.mkdir_p!()

    File.cp!(path, local_path)

    url = Path.join(Endpoint.url(), relative_path)

    {:ok, %{url: url, content_type: content_type}}
  end
end
