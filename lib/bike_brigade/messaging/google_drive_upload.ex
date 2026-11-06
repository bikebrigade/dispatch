defmodule BikeBrigade.Messaging.GoogleDriveUpload do
  alias BikeBrigade.Messaging
  alias BikeBrigade.Messaging.SmsMessage
  alias BikeBrigade.Riders.Rider

  alias BikeBrigade.Google.Drive

  alias BikeBrigade.LocalizedDateTime

  require Logger

  @folder "12avCsCaaNEtxcqvdUiijSQhWGyRBjC0B"

  @content_type_allowlist ~w(image/jpeg video/3gpp video/mp4)

  @doc """
  Uploads the message's media to Google Drive and saves the links.

  Items that are already uploaded or have a disallowed content type are left
  unchanged. A failed upload is logged and the item keeps no `gdrive_url`, so a
  later run retries it.
  """
  def upload_media(%SmsMessage{rider: rider} = message) do
    media =
      for m <- message.media do
        if m.content_type in @content_type_allowlist and is_nil(m.gdrive_url) do
          case Drive.upload_from_url(m.url, @folder,
                 name: file_name(rider, message),
                 content_type: m.content_type
               ) do
            {:ok, file} ->
              %{
                id: m.id,
                gdrive_url: file["webViewLink"],
                gdrive_folder_url: "https://drive.google.com/drive/folders/#{@folder}"
              }

            {:error, reason} ->
              Logger.error(
                "Failed to upload media #{m.id} of message #{message.id} to Google Drive: #{inspect(reason)}"
              )

              %{id: m.id}
          end
        else
          %{id: m.id}
        end
      end

    Messaging.update_sms_message(message, %{media: media})
  end

  defp file_name(%Rider{name: rider_name}, %SmsMessage{body: body, sent_at: sent_at}) do
    date =
      sent_at
      |> LocalizedDateTime.to_date()

    body = body || ""

    case Regex.scan(~r/I'm done with this (.*) delivery/, body, capture: :all_but_first) do
      [campaign] -> "#{date} - #{rider_name} - #{campaign}"
      [] -> "#{date} - #{rider_name}"
    end
  end
end
