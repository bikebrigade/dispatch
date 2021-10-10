defmodule BikeBrigade.DataMigrations.UploadMediaToDrive do
  import Ecto.Query, warn: false

  require Logger

  alias BikeBrigade.Repo
  alias BikeBrigade.Messaging.{SmsMessage, GoogleDriveUpload}

  def run() do
    q =
      from m in SmsMessage,
        where: fragment("? != '{}'", m.media),
        where: not is_nil(m.rider_id),
        preload: [:rider]

    messages = Repo.all(q)

    for m <- messages do
      Logger.info("Uploading #{m.id}")
      GoogleDriveUpload.upload_media(m)
    end
  end
end
