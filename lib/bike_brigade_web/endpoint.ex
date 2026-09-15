defmodule BikeBrigadeWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :bike_brigade
  require Logger


  if sandbox = Application.compile_env(:bike_brigade, :sandbox) do
    plug Phoenix.Ecto.SQL.Sandbox, sandbox: sandbox
  end

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_bike_brigade_key",
    signing_salt: "gRuTro4D",
    max_age: 2_592_000
  ]

  socket "/socket", BikeBrigadeWeb.UserSocket,
    websocket: true,
    longpoll: false

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]


  defp log_sandbox_requests(conn, _opts) do
    if conn.request_path == "/sandbox" do
      Logger.info("2@@@@@@@@@@@@@@@@@@@@@ SANDBOX REQUEST: #{conn.method} #{conn.request_path}")
    end
    conn
  end

  plug :log_sandbox_requests

  plug Phoenix.Ecto.SQL.Sandbox,
    at: "/sandbox",
    header: "x-session-id",
    repo: BikeBrigade.Repo,
    timeout: 15_000 # the default



  # Serve at "/static" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.

  plug Plug.Static,
    at: "/static",
    from: :bike_brigade,
    gzip: false,
    only: BikeBrigadeWeb.static_paths()

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :bike_brigade
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    body_reader: {CacheBodyReader, :read_body, []},
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug BikeBrigadeWeb.Router
end

defmodule CacheBodyReader do
  @moduledoc """
  Inspired by https://hexdocs.pm/plug/1.6.0/Plug.Parsers.html#module-custom-body-reader
  """

  alias Plug.Conn

  @cache_body_for_proxy_path "/analytics"

  @doc """
  Read the raw body and store it for later use in the connection.
  It ignores the updated connection returned by `Plug.Conn.read_body/2` to not break CSRF.
  """
  @spec read_body(Conn.t(), Plug.opts()) :: {:ok, String.t(), Conn.t()}
  def read_body(%Conn{request_path: @cache_body_for_proxy_path <> _} = conn, opts) do
    {:ok, body, _conn} = Conn.read_body(conn, opts)
    conn = update_in(conn.assigns[:raw_body], &[body | &1 || []])
    {:ok, body, conn}
  end

  def read_body(conn, opts), do: Conn.read_body(conn, opts)
end
