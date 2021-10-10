defmodule BikeBrigade.Google.Drive do
  def upload_from_url(url, parent, opts \\ []) do
    with {:ok, token} <- Goth.fetch(BikeBrigade.Google),
         conn <- GoogleApi.Storage.V1.Connection.new(token.token),
         {:ok, %HTTPoison.Response{body: body}} <- HTTPoison.get(url, [], follow_redirect: true) do
          GoogleApi.Drive.V3.Api.Files.drive_files_create_iodata(
            conn,
            "multipart",
            %GoogleApi.Drive.V3.Model.File{
              name: Keyword.get(opts, :name),
              parents: [parent],
              mimeType: Keyword.get(opts, :content_type)
            },
            body,
            supportsAllDrives: true,
            fields: "id, name, webViewLink"
          )
    end
  end
end
