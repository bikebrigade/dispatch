defmodule BikeBrigade.SelfiesTest do
  use ExUnit.Case, async: true

  alias BikeBrigade.Selfies

  @moduletag :tmp_dir

  # Real 8x8 images: JPEG, PNG and WebP from ffmpeg, HEIC from macOS sips
  @fixtures Path.expand("../support/fixtures/selfies", __DIR__)

  @rider %{name: "Ada Rider"}
  @campaign %{delivery_start: ~U[2026-11-20 15:00:00Z], program: %{name: "Food Bank"}}

  describe "detect_content_type/1 with real images" do
    for {file, type} <- [
          {"photo.jpg", "image/jpeg"},
          {"photo.png", "image/png"},
          {"photo.webp", "image/webp"},
          {"photo.heic", "image/heic"}
        ] do
      test "identifies #{file} as #{type}" do
        assert Selfies.detect_content_type(fixture(unquote(file))) == {:ok, unquote(type)}
      end
    end
  end

  describe "detect_content_type/1 HEIF brands" do
    test "a still image with only the generic mif1 brand is image/heif", %{tmp_dir: dir} do
      assert detect(dir, ftyp("mif1", ["mif1", "miaf"])) == {:ok, "image/heif"}
    end

    test "a compatible heic brand makes the file image/heic", %{tmp_dir: dir} do
      assert detect(dir, ftyp("mif1", ["mif1", "heic"])) == {:ok, "image/heic"}
    end

    for brand <- ~w(heix heim heis) do
      test "#{brand} is a still-image HEIC brand", %{tmp_dir: dir} do
        assert detect(dir, ftyp(unquote(brand), [unquote(brand), "mif1"])) ==
                 {:ok, "image/heic"}
      end
    end

    for brand <- ~w(msf1 hevc hevx hevm hevs) do
      test "rejects a sequence-only #{brand} file", %{tmp_dir: dir} do
        assert detect(dir, ftyp(unquote(brand), [unquote(brand), "iso8"])) ==
                 {:error, :unsupported_format}
      end
    end

    test "rejects a sequence with both sequence brands", %{tmp_dir: dir} do
      assert detect(dir, ftyp("msf1", ["msf1", "hevc"])) == {:error, :unsupported_format}
    end

    test "accepts a sequence file that also declares a still-image brand", %{tmp_dir: dir} do
      # Per the IANA registrations, a file that lists heic as a compatible
      # brand contains a HEIC still image, whatever its major brand
      assert detect(dir, ftyp("msf1", ["msf1", "hevc", "mif1", "heic"])) == {:ok, "image/heic"}
    end

    test "ignores brand-like bytes after the end of the ftyp box", %{tmp_dir: dir} do
      assert detect(dir, ftyp("msf1", ["msf1"]) <> "heic") == {:error, :unsupported_format}
    end
  end

  describe "detect_content_type/1 with empty, truncated, and unsupported input" do
    for {name, bytes} <- [
          {"an empty file", ""},
          {"two JPEG marker bytes", <<0xFF, 0xD8>>},
          {"half a PNG signature", <<0x89, "PNG">>},
          {"a RIFF header without the WebP chunk", "RIFF" <> <<0, 0, 0, 0>> <> "WEBP"},
          {"an ftyp box cut off before its brand", <<0, 0, 0, 24, "ftyp", "he">>},
          {"an ftyp box with an impossible size", <<0, 0, 0, 8, "ftyp", "heic", 0::32>>}
        ] do
      test "rejects #{name}", %{tmp_dir: dir} do
        assert detect(dir, unquote(bytes)) == {:error, :unsupported_format}
      end
    end

    for {name, bytes} <- [
          {"plain text", "just some text"},
          {"a GIF", "GIF89a" <> <<1, 0, 1, 0, 0, 0, 0>>},
          {"a WAV file", "RIFF" <> <<0, 0, 0, 0>> <> "WAVEfmt "},
          {"a RIFF WEBP header without VP", "RIFF" <> <<0, 0, 0, 0>> <> "WEBPXX"},
          {"an MP4 video", <<0, 0, 0, 24, "ftyp", "isom", 0::32, "isomavc1">>},
          {"a QuickTime video", <<0, 0, 0, 20, "ftyp", "qt  ", 0::32, "qt  ">>}
        ] do
      test "rejects #{name}", %{tmp_dir: dir} do
        assert detect(dir, unquote(bytes)) == {:error, :unsupported_format}
      end
    end
  end

  describe "detect_content_type/1 is signature sniffing, not image validation" do
    # These files are not decodable images; sniffing only sees their leading bytes
    test "a bare JPEG marker passes as image/jpeg", %{tmp_dir: dir} do
      assert detect(dir, <<0xFF, 0xD8, 0xFF>>) == {:ok, "image/jpeg"}
    end

    test "a bare PNG signature passes as image/png", %{tmp_dir: dir} do
      assert detect(dir, <<0x89, "PNG", 0x0D, 0x0A, 0x1A, 0x0A>>) == {:ok, "image/png"}
    end

    test "a truncated real JPEG passes as image/jpeg", %{tmp_dir: dir} do
      jpeg = File.read!(fixture("photo.jpg"))
      assert detect(dir, binary_part(jpeg, 0, 20)) == {:ok, "image/jpeg"}
    end
  end

  describe "upload/3" do
    setup do
      test_pid = self()

      Req.Test.stub(BikeBrigade.Google, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        send(test_pid, {:drive_upload, body})
        Req.Test.json(conn, %{"id" => "selfie-id"})
      end)

      :ok
    end

    for {file, type} <- [
          {"photo.jpg", "image/jpeg"},
          {"photo.png", "image/png"},
          {"photo.webp", "image/webp"},
          {"photo.heic", "image/heic"}
        ] do
      test "uploads #{file} to Drive as #{type}" do
        path = fixture(unquote(file))

        assert {:ok, %{"id" => "selfie-id"}} = Selfies.upload(path, @rider, @campaign)
        assert_received {:drive_upload, body}
        assert body =~ ~s("mimeType":"#{unquote(type)}")
        assert body =~ "Content-Type: #{unquote(type)}\r\n"
        assert body =~ File.read!(path)
        assert body =~ "2026-11-20 - Ada Rider - Food Bank"
      end
    end

    for {name, bytes} <- [
          {"an empty file", ""},
          {"plain text", "just some text"},
          {"a truncated PNG signature", <<0x89, "PNG">>},
          {"a HEIF sequence", <<0, 0, 0, 24, "ftyp", "msf1", 0::32, "msf1hevc">>}
        ] do
      test "never contacts Drive for #{name}", %{tmp_dir: dir} do
        path = write(dir, unquote(bytes))

        assert Selfies.upload(path, @rider, @campaign) == {:error, :unsupported_format}
        refute_received {:drive_upload, _}
      end
    end
  end

  defp fixture(name), do: Path.join(@fixtures, name)

  defp detect(dir, bytes), do: dir |> write(bytes) |> Selfies.detect_content_type()

  defp write(dir, bytes) do
    path = Path.join(dir, "upload-#{System.unique_integer([:positive])}")
    File.write!(path, bytes)
    path
  end

  # An ftyp box: size, "ftyp", major brand, minor version, compatible brands
  defp ftyp(major, compatible) do
    size = 16 + 4 * length(compatible)
    <<size::32, "ftyp", major::binary, 0::32>> <> Enum.join(compatible)
  end
end
