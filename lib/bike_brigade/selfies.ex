defmodule BikeBrigade.Selfies do
  @moduledoc "Uploads rider selfies to the same Drive folder used by incoming SMS media."

  alias BikeBrigade.Google.Drive
  alias BikeBrigade.LocalizedDateTime

  def folder, do: BikeBrigade.Messaging.GoogleDriveUpload.folder()

  # Enough for the WebP signature and an ftyp box with a dozen compatible brands
  @header_size 64

  # Still-image brands from the image/heic and image/heif IANA registrations.
  # Sequence brands (hevc, hevx, hevm, hevs, msf1) are deliberately absent.
  @heic_brands ~w(heic heix heim heis)
  @heif_brand "mif1"

  @doc """
  Uploads the photo at `path`, labelled with the content type from
  `detect_content_type/1` rather than the browser's. Anything that isn't a
  supported still photo returns `{:error, :unsupported_format}` without
  contacting Drive.
  """
  def upload(path, rider, campaign) do
    with {:ok, content_type} <- detect_content_type(path) do
      date = LocalizedDateTime.to_date(campaign.delivery_start)

      Drive.upload_file(path, folder(),
        name: "#{date} - #{rider.name} - #{campaign.program.name}",
        content_type: content_type
      )
    end
  end

  @doc """
  Identifies the likely format of the file at `path` from its leading bytes.

  Returns `{:ok, content_type}` for JPEG, PNG, WebP, and HEIC/HEIF still images,
  or `{:error, :unsupported_format}` otherwise, including empty files and HEIF
  files that carry only image sequence brands.

  This is signature sniffing, not validation: it checks a few magic bytes and
  does not decode the image. A file that starts with a valid signature but is
  truncated or corrupt after it (for example, just the three JPEG marker bytes)
  is still reported as that format.
  """
  def detect_content_type(path) do
    path
    |> File.open!([:read, :binary], &IO.binread(&1, @header_size))
    |> sniff()
  end

  defp sniff(<<0xFF, 0xD8, 0xFF, _::binary>>), do: {:ok, "image/jpeg"}
  defp sniff(<<0x89, "PNG", 0x0D, 0x0A, 0x1A, 0x0A, _::binary>>), do: {:ok, "image/png"}

  # WHATWG MIME Sniffing: "RIFF", 4 size bytes, then "WEBPVP"
  defp sniff(<<"RIFF", _size::binary-size(4), "WEBPVP", _::binary>>), do: {:ok, "image/webp"}

  defp sniff(<<size::32, "ftyp", major::binary-size(4), _minor::binary-size(4), rest::binary>>)
       when size >= 16 do
    brands = [major | compatible_brands(rest, size - 16)]

    cond do
      Enum.any?(brands, &(&1 in @heic_brands)) -> {:ok, "image/heic"}
      @heif_brand in brands -> {:ok, "image/heif"}
      true -> {:error, :unsupported_format}
    end
  end

  defp sniff(_header), do: {:error, :unsupported_format}

  # Compatible brands fill the rest of the ftyp box, four bytes each. Brands past
  # the bytes we read are ignored.
  defp compatible_brands(rest, length) do
    rest = binary_part(rest, 0, min(length, byte_size(rest)))
    for <<brand::binary-size(4) <- rest>>, do: brand
  end
end
