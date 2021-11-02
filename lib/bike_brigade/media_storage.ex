defmodule BikeBrigade.MediaStorage do
  use BikeBrigade.Adapter, :media_storage

  require Logger

  alias BikeBrigade.Utils

  @type path :: String.t()
  @type content_type :: String.t()
  @type bucket :: String.t()
  @type media_url :: String.t()
  @type response :: %{url: media_url, content_type: content_type}
  @type success :: {:ok, response}
  @type error :: {:error, any}

  @callback upload_file(path, content_type, bucket) :: success | error

  @spec upload_file(path, content_type) :: success | error
  @spec upload_file(path, content_type, bucket) :: success | error
  def upload_file(path, content_type, bucket \\ find_bucket()) do
    case @media_storage.upload_file(path, content_type, bucket) do
      {:ok, %{url: _, content_type: _} = response} ->
        {:ok, response}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec upload_file!(path, content_type) :: response
  @spec upload_file!(path, content_type, bucket) :: response
  def upload_file!(path, content_type, bucket \\ find_bucket()) do
    case @media_storage.upload_file(path, content_type, bucket) do
      {:ok, %{url: _, content_type: _} = response} ->
        response

      {:error, reason} ->
        message = "Failed to upload file #{path} (#{content_type} to #{bucket})"
        Logger.error("#{message}: #{inspect(reason)}")
        raise message
    end
  end

  defp find_bucket() do
    Utils.fetch_env!(:media_storage, :bucket)
  end
end
