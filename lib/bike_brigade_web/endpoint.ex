defmodule BikeBrigadeWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :bike_brigade

  if sandbox = Application.get_env(:bike_brigade, :sandbox) do
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

  # Serve at "/static" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.

  plug Plug.Static,
    at: "/static",
    from: :bike_brigade,
    gzip: false,
    only: ~w(assets fonts images robots.txt),
    only_matching: ~w(favicon)

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

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug BikeBrigadeWeb.Router
end
