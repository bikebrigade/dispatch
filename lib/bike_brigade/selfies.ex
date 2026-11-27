defmodule BikeBrigade.Selfies do
  @moduledoc "Uploads rider selfies to the same Drive folder used by incoming SMS media."

  alias BikeBrigade.Google.Drive
  alias BikeBrigade.LocalizedDateTime

  @folder "12avCsCaaNEtxcqvdUiijSQhWGyRBjC0B"

  def folder, do: @folder

  @heic_brands ~w(heic heix hevc heim heis hevm hevs)

  @doc """
  Uploads the photo at `path`. The content type comes from the file's leading
  bytes, not from the browser, and anything that isn't a supported photo
  returns `{:error, :unsupported_format}` without contacting Drive.
  """
  def upload(path, rider, campaign) do
    with {:ok, content_type} <- detect_content_type(path) do
      date = LocalizedDateTime.to_date(campaign.delivery_start)

      Drive.upload_file(path, @folder,
        name: "#{date} - #{rider.name} - #{campaign.program.name}",
        content_type: content_type
      )
    end
  end

  defp detect_content_type(path) do
    header = File.open!(path, [:read, :binary], &IO.binread(&1, 16))

    case header do
      <<0xFF, 0xD8, 0xFF, _::binary>> ->
        {:ok, "image/jpeg"}

      <<0x89, "PNG", 0x0D, 0x0A, 0x1A, 0x0A, _::binary>> ->
        {:ok, "image/png"}

      <<"RIFF", _size::binary-size(4), "WEBP", _::binary>> ->
        {:ok, "image/webp"}

      <<_size::binary-size(4), "ftyp", brand::binary-size(4), _::binary>>
      when brand in @heic_brands ->
        {:ok, "image/heic"}

      <<_size::binary-size(4), "ftyp", brand::binary-size(4), _::binary>>
      when brand in ~w(mif1 msf1) ->
        {:ok, "image/heif"}

      _ ->
        {:error, :unsupported_format}
    end
  end
end
