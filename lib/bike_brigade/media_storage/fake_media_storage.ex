defmodule BikeBrigade.MediaStorage.FakeMediaStorage do
  use GenServer

  alias BikeBrigade.MediaStorage

  @behaviour MediaStorage

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl MediaStorage
  def upload_file(path, content_type, bucket) do
    GenServer.call(__MODULE__, {:upload_file, path, content_type, bucket})
  end

  def last_upload() do
    GenServer.call(__MODULE__, :last_upload)
  end

  @impl GenServer
  def init(state), do: {:ok, state}

  @impl GenServer
  def handle_call({:upload_file, path, content_type, bucket}, _from, _) do
    url = request = %{path: path, content_type: content_type, bucket: bucket}

    response = {:ok, %{url: url, content_type: content_type}}
    {:reply, response, {request, response}}
  end

  def handle_call(:last_upload, _from, last_upload) do
    {:reply, last_upload, last_upload}
  end
end
