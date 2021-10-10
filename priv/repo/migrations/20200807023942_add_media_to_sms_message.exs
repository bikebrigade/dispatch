defmodule BikeBrigade.Repo.Migrations.AddMediaToSmsMessage do
  use Ecto.Migration

  import Ecto.Query

  alias BikeBrigade.Repo
  alias BikeBrigade.Messaging.SmsMessage

  require HTTPoison

  HTTPoison.start()

  def up do
    alter table(:sms_messages) do
      add(:media, :map)
    end

    flush()
    # migrate existing media, this includes calls to Twilio API!

    existing_media = from(m in "sms_messages", where: fragment("media_urls != '{}'"), select: {%{id: m.id}, fragment("media_urls")}) |> Repo.all()

    for {m, media_urls} <- existing_media do
      media =
        for media_url <- media_urls, media_url != nil do
          content_type =
            HTTPoison.head!(media_url, %{}, follow_redirect: true).headers
            |> Enum.find(fn {k, v} -> k == "Content-Type" end)
            |> elem(1)

          %SmsMessage.MediaItem{url: media_url, content_type: content_type}
        end

      Ecto.Changeset.change(m)
      |> Ecto.Changeset.put_embed(:media, media)
      |> Repo.update!()
    end

    flush()

    alter table(:sms_messages) do
      remove(:media_urls)
    end
  end

  def down do
    alter table(:sms_messages) do
      add(:media_urls, {:array, :string}, default: [])
    end

    flush()
    existing_media = from(m in SmsMessage, where: fragment("media != '{}'")) |> Repo.all()

    for m <- existing_media do
      media_urls =
        m.media
        |> Enum.map(& &1.url)

      Ecto.Changeset.change(m, %{media_urls: media_urls})
      |> Repo.update!()
    end

    alter table(:sms_messages) do
      remove(:media)
    end
  end
end
