defmodule BikeBrigade.Messaging.SmsMessage do
  use BikeBrigade.Schema
  import Ecto.Changeset

  alias BikeBrigade.Accounts.User
  alias BikeBrigade.Riders.Rider
  alias BikeBrigade.Delivery.Campaign

  alias BikeBrigade.EctoPhoneNumber

  defmodule MediaItem do
    use BikeBrigade.Schema

    embedded_schema do
      field :url, :string
      field :content_type, :string
      field :gdrive_url, :string
      field :gdrive_folder_url, :string
    end

    def changeset(sms_message, attrs) do
      sms_message
      |> cast(attrs, [:url, :content_type, :gdrive_url, :gdrive_folder_url])
      |> validate_required([:url, :content_type])
    end
  end

  schema "sms_messages" do
    field :incoming, :boolean
    field :body, :string
    field :from, EctoPhoneNumber.Canadian
    field :sent_at, :utc_datetime
    field :to, EctoPhoneNumber.Canadian
    field :twilio_sid, :string
    field :twilio_status, :string
    embeds_many :media, MediaItem
    belongs_to :campaign, Campaign
    belongs_to :rider, Rider #TODO: rename to sent_to_rider or sent_to
    belongs_to :sent_by_user, User

    timestamps()
  end

  @doc false
  def changeset(sms_message, attrs) do
    sms_message
    |> cast(attrs, [:to, :from, :body, :sent_at, :twilio_sid, :twilio_status, :incoming, :rider_id, :campaign_id, :sent_by_user_id])
    |> cast_embed(:media)
    |> validate_required([:to, :from])
    |> validate_required_inclusion([:body, :media])
  end

  def media_urls(%__MODULE__{} = message) do
    message.media
    |> Enum.map(fn m -> m.url end)
  end

  defp validate_required_inclusion(changeset, fields, error_message \\ nil) do
    if Enum.any?(fields, &present?(changeset, &1)) do
      changeset
    else
      # Add the error to the first field only since Ecto requires a field name for each error.
      error_message = error_message || "One of these fields must be present: #{inspect fields}"
      add_error(changeset, hd(fields), error_message)
    end
  end

  defp present?(changeset, field) do
    value = get_field(changeset, field)
    value && value != "" && value != []
  end

  @doc "Changeset used when sending messages. Only casts :body. Expects an %SmsMessage with the from rider and to filled out"
  def send_changeset(sms_message, attrs) do
    sms_message
    |> cast(attrs, [:body, :campaign_id])
    |> cast_embed(:media)
    # TODO may not need rider_id here
    |> validate_required([:to, :from, :rider_id])
    |> validate_required_inclusion([:body, :media], "Either a message or attached images are required.")
  end
end
